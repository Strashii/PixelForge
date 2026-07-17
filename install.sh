#!/usr/bin/env bash
# Dolphin Image Tools - Install script
# Instala el service menu de Dolphin para el usuario actual

set -euo pipefail

# Directorios de Service Menus según la versión de Plasma
PLASMA5_DIR="${HOME}/.local/share/kservices5/ServiceMenus"
PLASMA6_DIR="${HOME}/.local/share/kio/servicemenus"

readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly EXECUTABLE="${PROJECT_DIR}/scripts/image-tools.sh"
readonly TEMPLATE="${PROJECT_DIR}/servicemenu/dolphin-image-tools.desktop"
readonly DESKTOP_NAME="dolphin-image-tools.desktop"

# Dar permisos de ejecución
chmod +x "${PROJECT_DIR}/scripts/image-tools.sh"
chmod +x "${PROJECT_DIR}/scripts/actions/"*.sh 2>/dev/null || true

# Preparar el archivo desktop reemplazando el placeholder
TMP_DESKTOP="/tmp/${DESKTOP_NAME}"
sed "s|EXEC_PATH_PLACEHOLDER|\"${EXECUTABLE}\"|g" "${TEMPLATE}" > "${TMP_DESKTOP}"

installed=false

# Instalar para Plasma 5
if mkdir -p "${PLASMA5_DIR}" && cp "${TMP_DESKTOP}" "${PLASMA5_DIR}/${DESKTOP_NAME}"; then
    echo "Instalado exitosamente en Plasma 5 (${PLASMA5_DIR})"
    installed=true
fi

# Instalar para Plasma 6
if mkdir -p "${PLASMA6_DIR}" && cp "${TMP_DESKTOP}" "${PLASMA6_DIR}/${DESKTOP_NAME}"; then
    echo "Instalado exitosamente en Plasma 6 (${PLASMA6_DIR})"
    installed=true
fi

rm -f "${TMP_DESKTOP}"

if [[ "${installed}" == true ]]; then
    echo ""
    echo "✅ Instalación completada."
    echo "Nota: Puede que necesites reiniciar Dolphin o ejecutar 'kbuildsycoca5' / 'kbuildsycoca6' para que los cambios se reflejen inmediatamente."
else
    echo "❌ Error al intentar instalar el Service Menu."
    exit 1
fi
