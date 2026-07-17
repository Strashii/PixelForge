#!/usr/bin/env bash
# actions/convert.sh - Lógica para exportar/convertir formato de imágenes (API v1.0 Estabilizado)

# Metadatos del plugin
ACTION_ID="convert"
ACTION_NAME="Convertir formato (Convert)"
ACTION_DESCRIPTION="Exportar imágenes a formatos WEBP, PNG, JPG o AVIF"
ACTION_DEPENDENCIES=("magick")
ACTION_VERSION="1.0"
ACTION_API="1"

# Contrato estándar de ejecución
ACTION_PROCESS="convert_process_file"

_magick_cmd=""
_format=""
_quality=""

convert_process_file() {
    if [[ -n "${_quality}" && ("${_format}" == "jpg" || "${_format}" == "webp" || "${_format}" == "avif") ]]; then
        ${_magick_cmd} "$1" -quality "${_quality}" "$2"
    else
        ${_magick_cmd} "$1" "$2"
    fi
}

action_convert() {
    local files=("$@")

    # 1. Verificar dependencias
    require_imagemagick
    _magick_cmd=$(get_imagemagick_cmd)

    # 2. Solicitar Formato
    _format=$(dialog_convert_format)
    if [[ -z "${_format}" ]]; then exit 0; fi

    # 3. Solicitar Calidad (si aplica, con fallback a config)
    _quality=""
    if [[ "${_format}" == "jpg" || "${_format}" == "webp" || "${_format}" == "avif" ]]; then
        local default_q
        if [[ "${_format}" == "jpg" ]]; then
            default_q=$(config_get "JPEG_QUALITY")
        else
            default_q=$(config_get "WEBP_QUALITY")
        fi
        
        set +e
        _quality=$(kdialog --title "Calidad de Compresión" \
            --inputbox "Ingrese la calidad (1-100):" "${default_q}" 2>/dev/null)
        local status=$?
        set -e
        if [[ ${status} -ne 0 || -z "${_quality}" ]]; then exit 0; fi
    fi

    # 4. Solicitar Destino
    local dest_choice
    dest_choice=$(dialog_convert_destination)
    if [[ -z "${dest_choice}" ]]; then exit 0; fi

    local base_dir
    base_dir=$(dirname "${files[0]}")

    local custom_dir=""
    if [[ "${dest_choice}" == "custom" ]]; then
        custom_dir=$(dialog_select_directory "${base_dir}")
        if [[ -z "${custom_dir}" ]]; then exit 0; fi
    fi

    local folder_choice="${dest_choice}"
    if [[ "${dest_choice}" == "same_dir" ]]; then
        folder_choice="overwrite"
    fi

    local target_dir
    target_dir=$(get_destination_dir "${base_dir}" "${folder_choice}" "${custom_dir}" "Convert")

    # 5. Delegar al motor forzando la extensión elegida
    engine_process_files "${target_dir}" "Exportando imágenes" "Convirtiendo" "" "${_format}" "${files[@]}"
}

# Ejecutar sólo si no se está cargando metadatos
if [[ -z "${METADATA_ONLY:-}" ]]; then
    action_convert "$@"
fi
