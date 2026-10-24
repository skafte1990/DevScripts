#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: skafte1990
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/skafte1990/Enchantarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  mkvtoolnix \
  ffmpeg \
  vainfo \
  pciutils \
  libvulkan1 \
  mesa-vulkan-drivers \
  libgomp1
$STD apt install -y libmfx-gen1.2 || msg_warn "libmfx-gen1.2 not available, Intel QSV may be limited"
msg_ok "Installed Dependencies"

setup_hwaccel
PYTHON_VERSION="3.12" setup_uv

fetch_and_deploy_gh_release "dovi_tool" "quietvoid/dovi_tool" "prebuild" "latest" "/usr/local/bin" "dovi_tool-*-x86_64-unknown-linux-musl.tar.gz"
chmod +x /usr/local/bin/dovi_tool

fetch_and_deploy_gh_release "enchantarr" "skafte1990/Enchantarr" "prebuild" "latest" "/opt/enchantarr" "enchantarr-app.tar.gz" "app-"
fetch_and_deploy_gh_release "enchantarr-whisper" "skafte1990/Enchantarr" "prebuild" "whisper-v1" "/opt/whisper" "enchantarr-whisper.tar.gz"
chmod +x /opt/whisper/whisper-cli
cp -a /opt/whisper/lib/. /usr/local/lib/
ldconfig

msg_info "Setting up Enchantarr"
$STD uv venv /opt/enchantarr-venv
$STD uv pip install -p /opt/enchantarr-venv/bin/python -r /opt/enchantarr/backend/pyproject.toml
mkdir -p /data /downloads
cat <<EOF >/etc/enchantarr.env
ENCHANTARR_DATA_DIR=/data
ENCHANTARR_STAGING_DIR=/downloads/.enchantarr-staging
ENCHANTARR_GIT_SHA=$(cat /opt/enchantarr/.image_sha)
EOF
msg_ok "Set up Enchantarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/enchantarr.service
[Unit]
Description=Enchantarr
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/enchantarr
EnvironmentFile=/etc/enchantarr.env
ExecStart=/opt/enchantarr-venv/bin/uvicorn app.main:create_app --factory --host 0.0.0.0 --port 8000 --app-dir backend
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now enchantarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
