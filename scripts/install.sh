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

# Locate cli_linux directory that contains ncloud script (avoid SIGPIPE/broken pipe)
CLI_LINUX_DIR="$(find "${INSTALL_ROOT}" "${UNPACK_DIR}" -type f -path "*/cli_linux/ncloud" -print -quit | xargs -r dirname || true)"
if [[ -z "${CLI_LINUX_DIR}" ]]; then
  echo "ERROR: Could not locate cli_linux/ncloud after unzip." >&2
  exit 1
fi

chmod +x "${CLI_LINUX_DIR}/ncloud" || true

# Verify embedded JRE exists (it should be in the zip)
if [[ ! -f "${CLI_LINUX_DIR}/jre8/bin/java" ]]; then
  echo "ERROR: Embedded JRE not found at ${CLI_LINUX_DIR}/jre8/bin/java" >&2
  echo "Contents of ${CLI_LINUX_DIR}:" >&2
  ls -la "${CLI_LINUX_DIR}" >&2 || true
  echo "Search for java under CLI package:" >&2
  find "$(dirname "${CLI_LINUX_DIR}")" -maxdepth 4 -type f -path "*/bin/java" -print >&2 || true
  exit 1
fi
chmod +x "${CLI_LINUX_DIR}/jre8/bin/java" || true

# --- IMPORTANT FIX ---
# The upstream ncloud script uses relative paths (./jre8/bin/java).
# If you call it via an absolute path from elsewhere, it fails.
# Create a wrapper that always runs with CWD = CLI_LINUX_DIR.
if [[ ! -f "${CLI_LINUX_DIR}/ncloud.orig" ]]; then
  mv "${CLI_LINUX_DIR}/ncloud" "${CLI_LINUX_DIR}/ncloud.orig"
  cat > "${CLI_LINUX_DIR}/ncloud" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${DIR}"
exec "${DIR}/ncloud.orig" "$@"
EOF
  chmod +x "${CLI_LINUX_DIR}/ncloud"
fi

# Add CLI directory to PATH
echo "${CLI_LINUX_DIR}" >> "${GITHUB_PATH}"

# Expose outputs
{
  echo "cli-dir=${CLI_LINUX_DIR}"
  echo "ncloud-path=${CLI_LINUX_DIR}/ncloud"
} >> "${GITHUB_OUTPUT}"

echo "Installed NCLOUD CLI at: ${CLI_LINUX_DIR}"

# Sanity check: run from anywhere (wrapper handles cwd)
"${CLI_LINUX_DIR}/ncloud" help >/dev/null
