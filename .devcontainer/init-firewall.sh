#!/bin/bash
# DevContainer の iptables ファイアウォール初期化
# 参照: anthropics/claude-code/.devcontainer/init-firewall.sh
# OUTPUT を DROP、明示的に許可したドメインのみ通す

set -euo pipefail

echo "[firewall] Initializing iptables..."

# Close both families before any flush, DNS lookup or HTTP request. A failed
# command aborts startup; never restore ACCEPT policies on an error.
for firewall in iptables ip6tables; do
    for chain in INPUT OUTPUT FORWARD; do
        "$firewall" -P "$chain" DROP
    done
done

# Clear filter rules only. Docker's DNS resolver needs its existing NAT rules.
iptables -F
iptables -X
ip6tables -F
ip6tables -X

# ループバックは許可
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT
# Non-loopback IPv6 is intentionally disabled until an IPv6 allowlist exists.

# 確立済み接続の戻りを許可
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# DNS（53/UDP, 53/TCP）を許可
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# HTTPS のみ許可（80 と 443 のみ。それ以外は drop）
ALLOWED_DOMAINS=(
    "api.anthropic.com"
    "registry.npmjs.org"
    "registry.yarnpkg.com"
    "github.com"
    "api.github.com"
    "raw.githubusercontent.com"
    "objects.githubusercontent.com"
    "codeload.github.com"
    "pypi.org"
    "files.pythonhosted.org"
    "sentry.io"
    "statsig.anthropic.com"
    "marketplace.visualstudio.com"
    "vsmarketplacebadges.dev"
    "open-vsx.org"
)

# 各ドメインの IP を解決して許可
for domain in "${ALLOWED_DOMAINS[@]}"; do
    echo "[firewall] Resolving $domain..."
    IPS=$(getent ahostsv4 "$domain" | awk '{print $1}' | sort -u)
    if [ -z "$IPS" ]; then
        echo "[firewall] ERROR: failed to resolve $domain" >&2
        exit 1
    fi
    for ip in $IPS; do
        iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
        iptables -A OUTPUT -d "$ip" -p tcp --dport 80 -j ACCEPT
    done
done

# GitHub の IP レンジ（meta API）も許可
echo "[firewall] Fetching GitHub IP ranges..."
GH_META=$(curl -q --fail --silent --show-error --no-location --noproxy '*' \
    --proto '=https' --max-time 15 --connect-timeout 5 https://api.github.com/meta)
IPV4_RANGES=$(printf '%s' "$GH_META" | python3 -c '
import ipaddress, json, sys
metadata = json.load(sys.stdin)
ranges = set()
for group in ("web", "api", "git"):
    values = metadata[group]
    if not isinstance(values, list) or not values:
        raise ValueError("Missing GitHub IP ranges")
    networks = [ipaddress.ip_network(value) for value in values]
    ipv4 = {str(network) for network in networks if network.version == 4}
    if not ipv4:
        raise ValueError("Missing GitHub IPv4 ranges")
    ranges.update(ipv4)
print("\n".join(sorted(ranges)))
')
while IFS= read -r cidr; do
    iptables -A OUTPUT -d "$cidr" -p tcp --dport 443 -j ACCEPT
done <<< "$IPV4_RANGES"

echo "[firewall] ✅ Firewall initialized successfully."
echo "[firewall] Allowed domains:"
printf '  - %s\n' "${ALLOWED_DOMAINS[@]}"
