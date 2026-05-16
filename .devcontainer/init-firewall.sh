#!/bin/bash
# DevContainer の iptables ファイアウォール初期化
# 参照: anthropics/claude-code/.devcontainer/init-firewall.sh
# OUTPUT を DROP、明示的に許可したドメインのみ通す

set -euo pipefail

echo "[firewall] Initializing iptables..."

# 既存ルールクリア
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# ループバックは許可
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# 確立済み接続の戻りを許可
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

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
    IPS=$(getent ahosts "$domain" | awk '{print $1}' | sort -u || true)
    if [ -z "$IPS" ]; then
        echo "[firewall] WARN: failed to resolve $domain"
        continue
    fi
    for ip in $IPS; do
        iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
        iptables -A OUTPUT -d "$ip" -p tcp --dport 80 -j ACCEPT
    done
done

# GitHub の IP レンジ（meta API）も許可
echo "[firewall] Fetching GitHub IP ranges..."
GH_META=$(curl -fsSL https://api.github.com/meta 2>/dev/null || echo "")
if [ -n "$GH_META" ]; then
    for cidr in $(echo "$GH_META" | jq -r '.web[]?, .api[]?, .git[]?' 2>/dev/null); do
        iptables -A OUTPUT -d "$cidr" -p tcp --dport 443 -j ACCEPT
    done
fi

# それ以外の OUTPUT を DROP（戻り通信は ESTABLISHED で許可済み）
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

echo "[firewall] ✅ Firewall initialized successfully."
echo "[firewall] Allowed domains:"
printf '  - %s\n' "${ALLOWED_DOMAINS[@]}"
