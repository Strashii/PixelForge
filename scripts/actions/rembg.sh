#!/usr/bin/env bash
# actions/rembg.sh - Lógica para eliminar el fondo de las imágenes (Rembg++ v1.1)

# Metadatos del plugin
ACTION_ID="rembg"
ACTION_NAME="Eliminar fondo (Remove Background)"
ACTION_DESCRIPTION="Eliminar el fondo de las imágenes automáticamente usando varios modelos de rembg"
ACTION_DEPENDENCIES=("rembg")
ACTION_VERSION="1.1"
ACTION_API="1"

# Contrato estándar de ejecución
ACTION_PROCESS="rembg_process_file"
ACTION_BEFORE="rembg_before_process"

_model="u2net"
_matting="0"
_format="png"

rembg_before_process() {
    dialog_notify "Inicializando modelo de IA rembg...\nLa primera ejecución puede tardar un minuto mientras descarga el modelo."
}

rembg_process_file() {
    if [[ "${_matting}" == "1" ]]; then
        rembg i -m "${_model}" -a "$1" "$2"
    else
        rembg i -m "${_model}" "$1" "$2"
    fi
}

action_rembg() {
    local files=("$@")

    # 1. Verificar dependencias
    require_tool "rembg" "No se encontró 'rembg' en el sistema.\n\nPor favor, instala la herramienta (ej: 'pip install rembg') para poder eliminar fondos."

    # 2. Advertencia inicial (una sola vez mediante estado)
    if ! dialog_rembg_warning; then
        exit 0
    fi

    # 3. Solicitar Modelo
    _model=$(dialog_rembg_model)
    if [[ -z "${_model}" ]]; then exit 0; fi

    # 4. Solicitar Suavizado (Alpha Matting)
    _matting=$(dialog_rembg_matting)

    # 5. Solicitar Formato de Salida
    _format=$(dialog_rembg_format)
    if [[ -z "${_format}" ]]; then exit 0; fi

    # 6. Solicitar Destino
    local dest_choice
    dest_choice=$(dialog_rembg_destination)
    if [[ -z "${dest_choice}" ]]; then exit 0; fi

    local base_dir
    base_dir=$(dirname "${files[0]}")

    local custom_dir=""
    if [[ "${dest_choice}" == "custom" ]]; then
        custom_dir=$(dialog_select_directory "${base_dir}")
        if [[ -z "${custom_dir}" ]]; then exit 0; fi
    fi

    local target_dir
    target_dir=$(get_destination_dir "${base_dir}" "${dest_choice}" "${custom_dir}" "No-Background")

    # 7. Delegar al motor forzando la extensión elegida y sufijo _nobg
    engine_process_files "${target_dir}" "Eliminando fondo" "Extrayendo" "_nobg" "${_format}" "${files[@]}"
}

# Ejecutar sólo si no se está cargando metadatos
if [[ -z "${METADATA_ONLY:-}" ]]; then
    action_rembg "$@"
fi
