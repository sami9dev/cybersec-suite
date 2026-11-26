#!/usr/bin/env sh
# Install the latest verified standalone 0 binary for this host.
set -eu

REPO="0sec-labs/0security"
RELEASE_BASE_URL="${RELEASE_BASE_URL:-https://github.com/${REPO}/releases/latest/download}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.0/bin}"

fail() {
  printf '%s\n' "0 installer: $*" >&2
  exit 1
}

case "$(uname -s)" in
  Darwin)
    case "$(uname -m)" in
      arm64) ASSET="0-darwin-arm64" ;;
      *) fail "unsupported macOS architecture; download a matching release asset manually" ;;
    esac
    ;;
  Linux)
    case "$(uname -m)" in
      x86_64|amd64) ASSET="0-linux-x64" ;;
      aarch64|arm64) ASSET="0-linux-arm64" ;;
      *) fail "unsupported Linux architecture; download a matching release asset manually" ;;
    esac
    ;;
  *)
    fail "unsupported operating system; download the matching GitHub Release asset manually"
    ;;
esac

command -v curl >/dev/null 2>&1 || fail "curl is required"
if command -v sha256sum >/dev/null 2>&1; then
  sha256_file() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  sha256_file() { shasum -a 256 "$1" | awk '{print $1}'; }
else
  fail "sha256sum or shasum is required to verify the download"
fi

mkdir -p "$INSTALL_DIR"
manifest="$(mktemp "${TMPDIR:-/tmp}/0-checksums.XXXXXX")"
binary="$(mktemp "${INSTALL_DIR}/.${ASSET}.XXXXXX")"
fg_binary=""
cleanup() {
  rm -f "$manifest" "$binary" "$fg_binary"
}
trap cleanup EXIT HUP INT TERM

download() {
  task_download_url="$1"
  task_download_path="$2"
  shift 2
  if [ -t 2 ] && [ "${TERM:-}" != "dumb" ]; then
    curl --fail --location --progress-bar --show-error --retry 3 --retry-delay 1 "$@" "$task_download_url" -o "$task_download_path"
  else
    curl --fail --location --silent --show-error --retry 3 --retry-delay 1 "$@" "$task_download_url" -o "$task_download_path"
  fi
}
printf '%s\n' "Fetching release checksums…" >&2
curl --fail --location --silent --show-error --retry 3 --retry-delay 1 \
  "${RELEASE_BASE_URL}/checksums.txt" -o "$manifest"

# Provenance: checksums.txt is attested at release time (GitHub build-provenance
# attestation). When an authenticated `gh` is available, verify that attestation
# so the checksums come from this repository's release workflow and not only from
# whoever served the download. INSTALL_ATTESTATION=auto (default) verifies when
# possible and otherwise falls back to the checksums.txt integrity check below;
# `require` fails if it cannot verify; `0` skips (offline mirrors, air gaps).
INSTALL_ATTESTATION="${INSTALL_ATTESTATION:-auto}"
case "$INSTALL_ATTESTATION" in auto|require|0) ;; *) fail "INSTALL_ATTESTATION must be auto, require or 0" ;; esac
# Usage: attestation_verify <file> <owner/repo>; returns 0 only on a verified attestation.
attestation_verify() {
  gh attestation verify "$1" --repo "$2" >/dev/null 2>&1
}
attestation_usable() {
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}
if [ "$INSTALL_ATTESTATION" = "0" ]; then
  printf '%s\n' "Skipping attestation check (INSTALL_ATTESTATION=0); relying on checksums.txt only." >&2
elif attestation_usable; then
  printf '%s\n' "Verifying checksums.txt attestation with gh…" >&2
  if attestation_verify "$manifest" "$REPO"; then
    printf '%s\n' "checksums.txt attestation verified for ${REPO}." >&2
  else
    fail "could not verify the checksums.txt attestation for ${REPO}; refusing to install (set INSTALL_ATTESTATION=0 to skip when offline or using a mirror)"
  fi
elif [ "$INSTALL_ATTESTATION" = "require" ]; then
  fail "INSTALL_ATTESTATION=require needs an authenticated GitHub CLI (gh auth login)"
else
  printf '%s\n' "Note: gh is not installed or not logged in, so the release attestation was not verified; falling back to the checksums.txt integrity check. See https://docs.0.security/self-hosting/#verify-a-release to verify manually." >&2
fi

printf '%s\n' "Downloading ${ASSET}…" >&2
download "${RELEASE_BASE_URL}/${ASSET}" "$binary"

printf '%s\n' "Verifying ${ASSET}…" >&2
expected="$(awk -v asset="$ASSET" '$2 == asset || $2 == ("*" asset) { print $1; exit }' "$manifest")"
[ -n "$expected" ] || fail "checksums.txt has no entry for ${ASSET}"
actual="$(sha256_file "$binary")"
[ "$expected" = "$actual" ] || fail "checksum mismatch for ${ASSET}; refusing to install"

printf '%s\n' "Installing 0…" >&2
chmod 755 "$binary"
mv -f "$binary" "${INSTALL_DIR}/0"
binary=""
printf '%s\n' "Installed verified 0 to ${INSTALL_DIR}/0" >&2

# Provision the default static analyzer too, so standalone source reviews do
# not require Node/npm. INSTALL_FOXGUARD=0 opts out for pre-provisioned hosts.
if [ "${INSTALL_FOXGUARD:-1}" != "0" ]; then
  FOXGUARD_TAG="${FOXGUARD_TAG:-v0.14.2}"
  [ "$FOXGUARD_TAG" = "v0.14.2" ] || fail "update the pinned FoxGuard checksums before selecting another release"
  FOXGUARD_REPO="0sec-labs/foxguard"

  case "$(uname -s)" in
    Darwin)
      case "$(uname -m)" in
        arm64) FG_ASSET="foxguard-macos-aarch64"; FG_SHA256="d81086ad96f46e07c863f33b64be1c5e14013d92f8e3344c6f17a23d8f34772f" ;;
        *) fail "unsupported macOS architecture for FoxGuard companion" ;;
      esac ;;
    Linux)
      case "$(uname -m)" in
        x86_64|amd64) FG_ASSET="foxguard-linux-x86_64"; FG_SHA256="6996b73f5bd60eaa173908e585808a4df63595e09be34b1d7a5a70457a0ebec8" ;;
        aarch64|arm64) FG_ASSET="foxguard-linux-aarch64"; FG_SHA256="db6df4e455740488efef3be01df2217f825e0878ff1e4288e945db2133cabb7c" ;;
        *) fail "unsupported Linux architecture for FoxGuard companion" ;;
      esac ;;
    *) fail "unsupported operating system for FoxGuard companion" ;;
  esac

  if [ -x "${INSTALL_DIR}/foxguard" ]; then
    printf '%s\n' "Keeping existing FoxGuard at ${INSTALL_DIR}/foxguard" >&2
  else
    fg_binary="$(mktemp "${INSTALL_DIR}/.${FG_ASSET}.XXXXXX")"

    printf '%s\n' "Downloading FoxGuard ${FOXGUARD_TAG} companion (${FG_ASSET})…" >&2
    if download "https://github.com/${FOXGUARD_REPO}/releases/download/${FOXGUARD_TAG}/${FG_ASSET}" "$fg_binary" \
      --connect-timeout 10 --max-time 30 --retry 1 --retry-delay 1 --retry-max-time 35; then
      actual="$(sha256_file "$fg_binary")"
      if [ "$FG_SHA256" = "$actual" ]; then
        # The pinned SHA-256 above is the authority. An attestation, when the
        # companion's release publishes one, is reported as extra evidence only.
        if [ "$INSTALL_ATTESTATION" != "0" ] && attestation_usable; then
          if attestation_verify "$fg_binary" "$FOXGUARD_REPO"; then
            printf '%s\n' "FoxGuard attestation verified for ${FOXGUARD_REPO}." >&2
          else
            printf '%s\n' "No FoxGuard attestation verified; relying on the pinned SHA-256." >&2
          fi
        fi
        chmod 755 "$fg_binary"
        mv -f "$fg_binary" "${INSTALL_DIR}/foxguard"
        fg_binary=""
        printf '%s\n' "Installed verified FoxGuard to ${INSTALL_DIR}/foxguard" >&2
      else
        printf '%s\n' "0 installer: FoxGuard checksum mismatch; keeping 0 installed without the companion" >&2
      fi
    else
      printf '%s\n' "0 installer: FoxGuard download failed; keeping 0 installed without the companion" >&2
    fi
  fi
fi

# A piped installer cannot change its parent shell. Persist the path for future
# shells and print the exact command for the terminal that launched it.
quoted_dir="$(printf '%s' "$INSTALL_DIR" | sed "s/'/'\\\\''/g")"
path_line="export PATH='${quoted_dir}':\"\$PATH\""
add_path() {
  profile="$1"
  if ! grep -Fqx "$path_line" "$profile" 2>/dev/null; then
    if printf '\n# 0.security CLI\n%s\n' "$path_line" >> "$profile"; then
      printf '%s\n' "Added 0 to PATH in ${profile}" >&2
    else
      printf '%s\n' "Could not update ${profile}; add 0 to PATH manually" >&2
    fi
  fi
}
add_path "${HOME}/.profile"
case "${SHELL:-/bin/bash}" in
  */zsh) add_path "${ZDOTDIR:-${HOME}}/.zshrc" ;;
  */bash)
    add_path "${HOME}/.bashrc"
    if [ -f "${HOME}/.bash_profile" ]; then add_path "${HOME}/.bash_profile"
    elif [ -f "${HOME}/.bash_login" ]; then add_path "${HOME}/.bash_login"
    fi
    ;;
esac
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) ;;
  *) printf '\n%s\n%s\n' "To use 0 in this terminal, run:" "$path_line" >&2 ;;
esac
