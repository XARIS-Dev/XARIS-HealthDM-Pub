#!/usr/bin/env bash
# -----------------------------------------------------------------------
# HealthDM online installer
#
# Downloads the HealthDM release that matches this server (linux amd64 or arm64)
# from GitHub, verifies its SHA-256 checksum, and runs the release's own installer.
# The same command installs a new server or upgrades an existing installation.
#
#   curl -fsSL https://raw.githubusercontent.com/XARIS-Dev/XARIS-HealthDM-Pub/main/install.sh | bash
#
# Options (anything else is passed to the release installer):
#   --version vX.Y.Z   Install a specific release (default: the latest release)
#   --bind ADDR        Bind address, e.g. 0.0.0.0 to allow other machines (default: 127.0.0.1)
#   --port PORT        HTTP port (default: 8800)
#   --dir DIR          Install directory (default: the existing installation, else /opt/healthdm)
#   --backup-dir DIR   Where the mandatory pre-upgrade backup goes
# -----------------------------------------------------------------------

set -euo pipefail

REPO="XARIS-Dev/XARIS-HealthDM-Pub"

usage() {
  cat <<'USAGE'
Install or upgrade HealthDM from the latest GitHub release.

Usage: install.sh [--version vX.Y.Z] [--bind ADDR] [--port PORT] [--dir DIR] [--backup-dir DIR]

  --version vX.Y.Z  Install a specific release (default: the latest release)
  --bind ADDR       Bind address; 0.0.0.0 allows other machines (default: 127.0.0.1)
  --port PORT       HTTP port (default: 8800)
  --dir DIR         Install directory (default: the existing installation, else /opt/healthdm)
  --backup-dir DIR  Where the mandatory pre-upgrade backup goes
USAGE
}

fail() { echo "❌ $*" >&2; exit 1; }

# Everything runs inside main so the whole script is read before it starts (safe for curl | bash).
main() {
  local VERSION="${HEALTHDM_VERSION:-}"
  local INSTALL_ARGS=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version) VERSION="${2:?--version needs a value, e.g. v2.0.0}"; shift 2 ;;
      -h|--help)
        usage
        exit 0
        ;;
      *) INSTALL_ARGS+=("$1"); shift ;;
    esac
  done

  [[ "$(uname -s)" == "Linux" ]] || fail "HealthDM runs on Linux servers only."

  case "$(uname -m)" in
    x86_64|amd64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) fail "Unsupported CPU architecture: $(uname -m) (supported: amd64, arm64)." ;;
  esac

  for cmd in curl tar sha256sum; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Required: $cmd is not installed."
  done

  if [[ -z "$VERSION" ]]; then
    echo "Finding the latest HealthDM release..."
    latest_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")" \
      || fail "Could not reach github.com. Check the server's internet access."
    [[ "$latest_url" == */releases/tag/* ]] || fail "No HealthDM release has been published yet."
    VERSION="${latest_url##*/}"
  fi
  [[ "$VERSION" =~ ^[A-Za-z0-9_.-]{1,128}$ ]] || fail "Invalid version: $VERSION"

  BUNDLE="healthdm-${VERSION}-linux-${ARCH}"
  ARCHIVE="${BUNDLE}.tar.gz"
  CHECKSUMS="healthdm-${VERSION}-linux-checksums.sha256"
  BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

  WORK_DIR="$(mktemp -d "${HEALTHDM_TMPDIR:-/var/tmp}/healthdm-install.XXXXXX")"
  trap 'rm -rf "$WORK_DIR"' EXIT
  cd "$WORK_DIR"

  echo "Downloading HealthDM ${VERSION} for linux/${ARCH}..."
  curl -fL --retry 3 --progress-bar -o "$ARCHIVE" "${BASE_URL}/${ARCHIVE}" \
    || fail "Download failed: ${BASE_URL}/${ARCHIVE}"
  curl -fsSL --retry 3 -o "$CHECKSUMS" "${BASE_URL}/${CHECKSUMS}" \
    || fail "Download failed: ${BASE_URL}/${CHECKSUMS}"

  echo "Verifying checksum..."
  grep -E "[[:space:]]\*?${ARCHIVE}\$" "$CHECKSUMS" | sha256sum -c - \
    || fail "Checksum verification failed for ${ARCHIVE}. Nothing was installed."

  echo "Extracting..."
  tar -xzf "$ARCHIVE"
  rm -f "$ARCHIVE"
  [[ -f "${BUNDLE}/install.sh" ]] || fail "The release archive does not contain ${BUNDLE}/install.sh."

  bash "${BUNDLE}/install.sh" ${INSTALL_ARGS[@]+"${INSTALL_ARGS[@]}"} </dev/null
}

main "$@"
