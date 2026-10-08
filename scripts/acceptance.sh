#!/usr/bin/env bash
# Live acceptance for the lab. Needs az login (with your IP in the AKS and Key Vault allow-lists), kubectl, jq, curl, nc.
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 --rg <rg> --aks <aks-name> --hostname <tfe-fqdn> --key-vault <kv-name> --org <org> [--admin-user <name>]
  --admin-user defaults to tfeadmin. -h, --help prints this text.
USAGE
}

RG="" AKS="" HOST="" KV="" ORG="" ADMIN_USER="tfeadmin"
need_val() { [[ $# -ge 2 ]] || { echo "flag $1 needs a value" >&2; usage >&2; exit 2; }; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --rg) need_val "$@"; RG="$2"; shift 2 ;;
    --aks) need_val "$@"; AKS="$2"; shift 2 ;;
    --hostname) need_val "$@"; HOST="$2"; shift 2 ;;
    --key-vault) need_val "$@"; KV="$2"; shift 2 ;;
    --org) need_val "$@"; ORG="$2"; shift 2 ;;
    --admin-user) need_val "$@"; ADMIN_USER="$2"; shift 2 ;;
    *) echo "unknown flag $1" >&2; usage >&2; exit 2 ;;
  esac
done
if [[ -z "$RG" || -z "$AKS" || -z "$HOST" || -z "$KV" || -z "$ORG" ]]; then
  echo "required: --rg --aks --hostname --key-vault --org" >&2
  usage >&2
  exit 1
fi

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

az aks get-credentials -g "$RG" -n "$AKS" --admin --overwrite-existing >/dev/null || fail "could not get AKS credentials for $AKS in $RG"
kubectl -n tfe rollout status deployment/terraform-enterprise --timeout=120s >/dev/null || fail "TFE deployment not ready"
pass "TFE pods ready"

if command -v lsof >/dev/null 2>&1; then
  ! lsof -nP -iTCP:8443 -sTCP:LISTEN >/dev/null 2>&1 || fail "127.0.0.1:8443 is already in use; stop the other port-forward and re-run"
elif nc -z 127.0.0.1 8443 >/dev/null 2>&1; then
  fail "127.0.0.1:8443 is already in use; stop the other port-forward and re-run"
fi

kubectl -n tfe port-forward svc/terraform-enterprise 8443:443 >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true' EXIT
ready=""
for _ in $(seq 1 20); do
  if nc -z 127.0.0.1 8443 >/dev/null 2>&1; then ready=1; break; fi
  kill -0 "$PF" 2>/dev/null || fail "kubectl port-forward exited before port 8443 opened"
  sleep 1
done
[[ -n "$ready" ]] || fail "port-forward did not open 127.0.0.1:8443 within 20 seconds"

CURL=(curl -sS --max-time 20 --resolve "$HOST:8443:127.0.0.1")
code=$("${CURL[@]}" -o /dev/null -w '%{http_code}' "https://$HOST:8443/api/v1/health/readiness") || fail "TLS or connection error (certificate must verify)"
[[ "$code" == "200" ]] || fail "readiness returned $code"
pass "readiness 200 with a trusted certificate"

TOKEN=$(az keyvault secret show --vault-name "$KV" -n tfe-admin-token --query value -o tsv) || fail "could not read tfe-admin-token from Key Vault $KV"
user=$("${CURL[@]}" -H "Authorization: Bearer $TOKEN" "https://$HOST:8443/api/v2/account/details" | jq -r '.data.attributes.username') || fail "account details request or parse failed"
[[ "$user" == "$ADMIN_USER" ]] || fail "admin token check returned '$user', expected '$ADMIN_USER'"
pass "admin token works"

org=$("${CURL[@]}" -H "Authorization: Bearer $TOKEN" "https://$HOST:8443/api/v2/organizations/$ORG" | jq -r '.data.id') || fail "organization request or parse failed"
[[ "$org" == "$ORG" ]] || fail "organization $ORG not found"
pass "organization exists"

team=$("${CURL[@]}" -H "Authorization: Bearer $TOKEN" "https://$HOST:8443/api/v2/organizations/$ORG/teams?filter%5Bnames%5D=platform" | jq -r '.data[0].attributes.name') || fail "teams request or parse failed"
[[ "$team" == "platform" ]] || fail "platform team not found"
pass "platform team exists"

# A real run proves Sidekiq and the agents work; readiness passes even when Sidekiq can't fetch jobs.
API=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.api+json")
B="https://$HOST:8443/api/v2"
ws=$("${CURL[@]}" "${API[@]}" "$B/organizations/$ORG/workspaces/acceptance-smoke" | jq -r '.data.id // empty') || fail "workspace lookup failed"
if [[ -z "$ws" ]]; then
  ws=$("${CURL[@]}" "${API[@]}" -X POST "$B/organizations/$ORG/workspaces" \
    -d '{"data":{"type":"workspaces","attributes":{"name":"acceptance-smoke","auto-apply":true}}}' | jq -r '.data.id // empty') || fail "workspace create failed"
  [[ -n "$ws" ]] || fail "could not create workspace acceptance-smoke"
fi
cfg=$(mktemp -d)
trap 'kill $PF 2>/dev/null || true; rm -rf "$cfg"' EXIT
mkdir "$cfg/src"
echo 'resource "terraform_data" "smoke" { input = timestamp() }' > "$cfg/src/main.tf"
tar -czf "$cfg/cfg.tgz" -C "$cfg/src" .
cv=$("${CURL[@]}" "${API[@]}" -X POST "$B/workspaces/$ws/configuration-versions" \
  -d '{"data":{"type":"configuration-versions","attributes":{"auto-queue-runs":false}}}') || fail "configuration version create failed"
cv_id=$(jq -r '.data.id' <<<"$cv")
upload=$(jq -r '.data.attributes["upload-url"]' <<<"$cv" | sed "s#https://$HOST/#https://$HOST:8443/#")
"${CURL[@]}" -X PUT -H "Content-Type: application/octet-stream" --data-binary @"$cfg/cfg.tgz" "$upload" -o /dev/null || fail "configuration upload failed"
sleep 3
run=$("${CURL[@]}" "${API[@]}" -X POST "$B/runs" -d "{\"data\":{\"type\":\"runs\",\"attributes\":{\"message\":\"acceptance\"},\"relationships\":{\"workspace\":{\"data\":{\"type\":\"workspaces\",\"id\":\"$ws\"}},\"configuration-version\":{\"data\":{\"type\":\"configuration-versions\",\"id\":\"$cv_id\"}}}}}" | jq -r '.data.id // empty') || fail "run create failed"
[[ -n "$run" ]] || fail "run was not created"
status=""
for _ in $(seq 1 40); do
  status=$("${CURL[@]}" "${API[@]}" "$B/runs/$run" | jq -r '.data.attributes.status') || status="(request failed)"
  case "$status" in applied) break ;; errored|discarded|canceled|force_canceled) fail "run $run ended $status" ;; esac
  sleep 15
done
[[ "$status" == "applied" ]] || fail "run $run still '$status' after 10 minutes (pending means Sidekiq or agents are not picking up work)"
pass "a run plans and applies ($run)"

echo "ALL CHECKS PASSED"
