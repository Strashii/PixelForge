#!/usr/bin/env bash
# Dolphin Image Tools - Uninstall script
# Desinstala el service menu de Dolphin para el usuario actual

set -euo pipefail

PLASMA5_DIR="${HOME}/.local/share/kservices5/ServiceMenus"
PLASMA6_DIR="${HOME}/.local/share/kio/servicemenus"
DESKTOP_NAME="dolphin-image-tools.desktop"

removed=false

if [[ -f "${PLASMA5_DIR}/${DESKTOP_NAME}" ]]; then
    rm -f "${PLASMA5_DIR}/${DESKTOP_NAME}"
    echo "Eliminado de Plasma 5 (${PLASMA5_DIR})"
    removed=true
fi

if [[ -f "${PLASMA6_DIR}/${DESKTOP_NAME}" ]]; then
    rm -f "${PLASMA6_DIR}/${DESKTOP_NAME}"
    echo "Eliminado de Plasma 6 (${PLASMA6_DIR})"
    removed=true
fi

if [[ "${removed}" == true ]]; then
    echo "✅ Desinstalación completada."
    echo "Nota: Puede que necesites reiniciar Dolphin para que los cambios se reflejen."
else
    echo "⚠️ No se encontró la extensión instalada."
fi
