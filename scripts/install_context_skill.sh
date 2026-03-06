#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_SKILL_DIR="${ROOT_DIR}/skills/context-bootstrap"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
DEST_SKILL_DIR="${CODEX_HOME}/skills/context-bootstrap"
LOCAL_BIN_DIR="${HOME}/.local/bin"
LAUNCHER="${LOCAL_BIN_DIR}/context-bootstrap"

if [[ ! -f "${SRC_SKILL_DIR}/SKILL.md" ]]; then
  echo "[ERROR] skill source not found: ${SRC_SKILL_DIR}"
  exit 1
fi

mkdir -p "${CODEX_HOME}/skills"
rm -rf "${DEST_SKILL_DIR}"
cp -R "${SRC_SKILL_DIR}" "${DEST_SKILL_DIR}"

if [[ -f "${DEST_SKILL_DIR}/scripts/bootstrap_context.sh" ]]; then
  chmod +x "${DEST_SKILL_DIR}/scripts/bootstrap_context.sh"
fi

mkdir -p "${LOCAL_BIN_DIR}"
cat > "${LAUNCHER}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "${DEST_SKILL_DIR}/scripts/bootstrap_context.sh" "\$@"
EOF
chmod +x "${LAUNCHER}"

echo "[OK] Installed skill: ${DEST_SKILL_DIR}"
echo "[OK] Installed launcher: ${LAUNCHER}"
echo
echo "Unified command:"
echo "context-bootstrap \"飞书 联调 鉴权 记忆\" 5"
echo
echo "If command not found, add to PATH:"
echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
