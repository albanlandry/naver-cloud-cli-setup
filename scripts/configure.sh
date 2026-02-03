#!/usr/bin/env bash
set -euo pipefail

ACCESS_KEY_ID="${1}"
SECRET_ACCESS_KEY="${2}"
API_URL="${3}"
PROFILE="${4:-DEFAULT}"
EXPORT_ENV="${5:-true}"

CONFIG_DIR="${HOME}/.ncloud"
CONFIG_PATH="${CONFIG_DIR}/configure"

mkdir -p "${CONFIG_DIR}"
chmod 700 "${CONFIG_DIR}" || true

echo "::add-mask::${ACCESS_KEY_ID}"
echo "::add-mask::${SECRET_ACCESS_KEY}"

cat > "${CONFIG_PATH}" <<EOF
[DEFAULT]
ncloud_access_key_id = ${ACCESS_KEY_ID}
ncloud_secret_access_key = ${SECRET_ACCESS_KEY}
ncloud_api_url = ${API_URL}
EOF

if [[ "${PROFILE}" != "DEFAULT" ]]; then
  cat >> "${CONFIG_PATH}" <<EOF

[${PROFILE}]
ncloud_access_key_id = ${ACCESS_KEY_ID}
ncloud_secret_access_key = ${SECRET_ACCESS_KEY}
ncloud_api_url = ${API_URL}
EOF
fi

chmod 600 "${CONFIG_PATH}" || true

if [[ "${EXPORT_ENV}" == "true" ]]; then
  {
    echo "NCLOUD_ACCESS_KEY=${ACCESS_KEY_ID}"
    echo "NCLOUD_SECRET_KEY=${SECRET_ACCESS_KEY}"
    echo "NCLOUD_API_GW=${API_URL}"
  } >> "${GITHUB_ENV}"
fi

echo "config-path=${CONFIG_PATH}" >> "${GITHUB_OUTPUT}"
echo "Wrote ${CONFIG_PATH}"
