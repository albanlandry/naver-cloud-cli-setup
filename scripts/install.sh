#!/usr/bin/env bash
set -euo pipefail

DOWNLOAD_URL_INPUT="${1:-}"
DOCS_PAGE="${2:-https://cli.ncloud-docs.com/docs/en/guide-clichange}"
INSTALL_ROOT_INPUT="${3:-}"

if [[ -n "${INSTALL_ROOT_INPUT}" ]]; then
  INSTALL_ROOT="${INSTALL_ROOT_INPUT}"
else
  INSTALL_ROOT="${RUNNER_TOOL_CACHE:-/tmp}/ncloud-cli"
fi

mkdir -p "${INSTALL_ROOT}"

resolve_download_url() {
  if [[ -n "${DOWNLOAD_URL_INPUT}" ]]; then
    echo "${DOWNLOAD_URL_INPUT}"
    return 0
  fi

  local html
  html="$(curl -fsSL "${DOCS_PAGE}")"

  local url
  url="$(echo "${html}" | grep -oE 'https://www\.ncloud\.com/api/support/download/files/cli/CLI_[0-9.]+_[0-9]+\.zip' | head -n 1 || true)"
  if [[ -z "${url}" ]]; then
    echo "ERROR: Could not find CLI zip URL on docs page: ${DOCS_PAGE}" >&2
    exit 1
  fi
  echo "${url}"
}

DOWNLOAD_URL="$(resolve_download_url)"
ZIP_PATH="${INSTALL_ROOT}/ncloud-cli.zip"
UNPACK_DIR="${INSTALL_ROOT}/unpacked"

if find "${INSTALL_ROOT}" -type f -name "ncloud" -path "*/cli_linux/*" | grep -q .; then
  echo "NCLOUD CLI already present under ${INSTALL_ROOT}. Skipping download."
else
  rm -rf "${UNPACK_DIR}"
  mkdir -p "${UNPACK_DIR}"
  echo "Downloading NCLOUD CLI from: ${DOWNLOAD_URL}"
  curl -fL --retry 3 --retry-delay 2 -o "${ZIP_PATH}" "${DOWNLOAD_URL}"
  echo "Unzipping..."
  unzip -q -o "${ZIP_PATH}" -d "${UNPACK_DIR}"
fi

CLI_LINUX_DIR="$(find "${INSTALL_ROOT}" "${UNPACK_DIR}" -type f -name "ncloud" -path "*/cli_linux/ncloud" -print0 | xargs -0 -n1 dirname | head -n 1 || true)"
if [[ -z "${CLI_LINUX_DIR}" ]]; then
  echo "ERROR: Could not locate cli_linux/ncloud after unzip." >&2
  exit 1
fi

chmod +x "${CLI_LINUX_DIR}/ncloud" || true
if [[ -f "${CLI_LINUX_DIR}/jre8/bin/java" ]]; then
  chmod +x "${CLI_LINUX_DIR}/jre8/bin/java" || true
fi

echo "${CLI_LINUX_DIR}" >> "${GITHUB_PATH}"

{
  echo "cli-dir=${CLI_LINUX_DIR}"
  echo "ncloud-path=${CLI_LINUX_DIR}/ncloud"
} >> "${GITHUB_OUTPUT}"

echo "Installed NCLOUD CLI at: ${CLI_LINUX_DIR}"
"${CLI_LINUX_DIR}/ncloud" help >/dev/null
