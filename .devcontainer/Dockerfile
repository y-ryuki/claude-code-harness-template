FROM node:26-bookworm

ARG TZ=Asia/Tokyo
ENV TZ=$TZ DEBIAN_FRONTEND=noninteractive

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    ripgrep \
    fzf \
    vim \
    less \
    sudo \
    iptables \
    ipset \
    dnsutils \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

# Python tooling (ruff, etc.)
RUN pip install --no-cache-dir --break-system-packages \
    ruff \
    black \
    mypy \
    pytest

# gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update && apt-get install -y gh \
  && rm -rf /var/lib/apt/lists/*

# gitleaks
RUN GL_VERSION=8.21.4 \
  && curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${GL_VERSION}/gitleaks_${GL_VERSION}_linux_x64.tar.gz" \
    -o /tmp/gitleaks.tar.gz \
  && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks \
  && rm /tmp/gitleaks.tar.gz

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code@latest

# node ユーザーに sudo を付与（firewall設定のみ）
RUN echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall \
  && chmod 0440 /etc/sudoers.d/node-firewall

# firewall スクリプトを配置
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh

# managed-settings を配置（チーム強制設定用、必要に応じて）
# COPY managed-settings.json /etc/claude-code/managed-settings.json

USER node
WORKDIR /workspace

CMD ["sleep", "infinity"]
