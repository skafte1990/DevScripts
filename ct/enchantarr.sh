#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: skafte1990
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/skafte1990/Enchantarr

APP="Enchantarr"
var_tags="${var_tags:-arr;media}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"
var_gpu="${var_gpu:-yes}"
var_arm64="${var_arm64:-no}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/enchantarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "enchantarr" "skafte1990/Enchantarr" "" "" "app-"; then
    msg_info "Stopping Enchantarr"
    systemctl stop enchantarr
    msg_ok "Stopped Enchantarr"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "enchantarr" "skafte1990/Enchantarr" "prebuild" "latest" "/opt/enchantarr" "enchantarr-app.tar.gz" "app-"

    msg_info "Updating Enchantarr"
    $STD uv pip install -U -p /opt/enchantarr-venv/bin/python -r /opt/enchantarr/backend/pyproject.toml
    sed -i "s/^OPTIMARR_GIT_SHA=.*/OPTIMARR_GIT_SHA=$(cat /opt/enchantarr/.image_sha)/" /etc/enchantarr.env
    msg_ok "Updated Enchantarr"

    msg_info "Starting Enchantarr"
    systemctl start enchantarr
    msg_ok "Started Enchantarr"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
