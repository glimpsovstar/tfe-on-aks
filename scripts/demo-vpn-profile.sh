#!/usr/bin/env bash
# Builds the laptop side of the optional demo VPN (bootstrap enable_demo_vpn = true):
#   - a client .p12 for the macOS keychain
#   - the Azure VPN Client profile (azurevpnconfig.xml) with the private resolver as DNS server
# Everything goes to demo-vpn/ (git-ignored). Keys are never printed or written anywhere else.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
out="$repo/demo-vpn"
tf=(terraform -chdir="$repo/bootstrap")

for cmd in terraform openssl az curl unzip python3; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "missing required command: $cmd" >&2; exit 1; }
done

umask 077
mkdir -p "$out"

echo "==> Reading bootstrap outputs"
gw=$("${tf[@]}" output -raw demo_vpn_gateway_name 2>/dev/null || true)
dns_ip=$("${tf[@]}" output -raw demo_vpn_dns_server_ip 2>/dev/null || true)
if [[ -z "$gw" || -z "$dns_ip" ]]; then
  echo "demo VPN outputs are empty. Set enable_demo_vpn = true in bootstrap/terraform.tfvars and apply first." >&2
  exit 1
fi
tfe_host=$("${tf[@]}" output -raw tfe_hostname)
zone=${tfe_host#tfe.}
aks=$("${tf[@]}" output -raw aks_cluster_name)
rg="${aks%-tfe-aks}-tfe-rg"
echo "gateway: $gw   resource group: $rg   DNS server: $dns_ip   zone: $zone"

echo "==> Writing certificate and key (not printed)"
"${tf[@]}" output -raw demo_vpn_client_cert_pem >"$out/client.crt"
"${tf[@]}" output -raw demo_vpn_client_key_pem >"$out/client.key"
"${tf[@]}" output -raw demo_vpn_root_cert_pem >"$out/root.crt"

echo "==> Building client.p12"
read -r -s -p "Export password for client.p12 (you type it again when importing into Keychain): " p12pass
echo
[[ -n "$p12pass" ]] || { echo "password must not be empty" >&2; exit 1; }
legacy=()
# macOS Keychain cannot read the default OpenSSL 3 PKCS#12 encryption; LibreSSL and OpenSSL 1.x do not need the flag.
if openssl version | grep -q '^OpenSSL 3'; then
  legacy=(-legacy)
fi
P12_PASS=$p12pass openssl pkcs12 -export "${legacy[@]}" \
  -inkey "$out/client.key" -in "$out/client.crt" -certfile "$out/root.crt" \
  -name "demo-vpn-client" -passout env:P12_PASS -out "$out/client.p12"
unset p12pass

echo "==> Downloading the VPN client profile from Azure"
url=$(az network vnet-gateway vpn-client generate -g "$rg" -n "$gw" --authentication-method EAPTLS -o tsv)
url=${url//\"/}
curl -fsSL "$url" -o "$out/vpnclient.zip"
unzip -p "$out/vpnclient.zip" AzureVPN/azurevpnconfig.xml >"$out/azurevpnconfig.xml"

echo "==> Adding DNS server and suffix to the profile"
python3 - "$out/azurevpnconfig.xml" "$dns_ip" ".$zone" <<'PY'
import sys
import xml.etree.ElementTree as ET

path, dns_ip, suffix = sys.argv[1:4]
tree = ET.parse(path)
root = tree.getroot()

# Keep the file's own namespaces so the Azure VPN Client still accepts it.
ns_default = root.tag[1:].split("}")[0] if root.tag.startswith("{") else ""
ET.register_namespace("", ns_default)
ET.register_namespace("i", "http://www.w3.org/2001/XMLSchema-instance")

def local(tag):
    return tag.split("}")[-1]

def qn(name):
    return f"{{{ns_default}}}{name}" if ns_default else name

cfg = next((e for e in root.iter() if local(e.tag).lower() == "clientconfig"), None)
if cfg is None:
    sys.exit("no <clientconfig> element found in azurevpnconfig.xml")

for child in list(cfg):
    if local(child.tag).lower() in ("dnsservers", "dnssuffixes"):
        cfg.remove(child)

servers = ET.Element(qn("dnsservers"))
ET.SubElement(servers, qn("dnsserver")).text = dns_ip
suffixes = ET.Element(qn("dnssuffixes"))
ET.SubElement(suffixes, qn("dnssuffix")).text = suffix

# The client reads a data contract, which orders members alphabetically; insert in that order.
for new in (servers, suffixes):
    pos = len(cfg)
    for i, child in enumerate(cfg):
        if local(child.tag).lower() > local(new.tag).lower():
            pos = i
            break
    cfg.insert(pos, new)

tree.write(path, encoding="utf-8", xml_declaration=True)
PY

rm -f "$out/client.key" "$out/vpnclient.zip"

cat <<MSG

Done. Files are in $out (git-ignored):
  client.p12          client certificate and key, protected by your export password
  azurevpnconfig.xml  Azure VPN Client profile (DNS server $dns_ip, suffix .$zone)
  root.crt, client.crt

Next steps:
  1. Install "Azure VPN Client" from the Mac App Store.
  2. Double-click client.p12 to import it into the login keychain (enter the export password).
  3. In Azure VPN Client: Import $out/azurevpnconfig.xml, choose the "demo-vpn-client" certificate, Save, Connect.
  4. Open https://$tfe_host
MSG
