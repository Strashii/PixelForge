#!/usr/bin/env bash
# actions/resize.sh - Lógica para redimensionar imágenes (API v1.0 Estabilizado)

# Metadatos del plugin
ACTION_ID="resize"
ACTION_NAME="Redimensionar (Resize)"
ACTION_DESCRIPTION="Redimensionar imágenes por lote con tamaños predefinidos o personalizados"
ACTION_DEPENDENCIES=("magick")
ACTION_VERSION="1.0"
ACTION_API="1"

# Contrato estándar de ejecución
ACTION_PROCESS="resize_process_file"

_magick_cmd=""
_geometry=""

resize_process_file() {
    ${_magick_cmd} "$1" -resize "${_geometry}" "$2"
}

action_resize() {
    local files=("$@")

    # 1. Verificar dependencias
    require_imagemagick
    _magick_cmd=$(get_imagemagick_cmd)

    # 2. Solicitar Tamaño
    local size_choice
    size_choice=$(dialog_resize_size)
    if [[ -z "${size_choice}" ]]; then exit 0; fi

    if [[ "${size_choice}" == "custom" ]]; then
        local custom_data
        custom_data=$(dialog_resize_custom)
        if [[ -z "${custom_data}" ]]; then exit 0; fi

        local res keep
        res=$(echo "${custom_data}" | awk '{print $1}')
        keep=$(echo "${custom_data}" | awk '{print $2}')

        if [[ "${keep}" == "1" ]]; then
            _geometry="${res}"
        else
            _geometry="${res}!"
        fi
    else
        _geometry="${size_choice}"
    fi

    # 3. Solicitar Destino
    local dest_choice
    dest_choice=$(dialog_resize_destination)
    if [[ -z "${dest_choice}" ]]; then exit 0; fi

    local base_dir
    base_dir=$(dirname "${files[0]}")

    local custom_dir=""
    if [[ "${dest_choice}" == "custom" ]]; then
        custom_dir=$(dialog_select_directory "${base_dir}")
        if [[ -z "${custom_dir}" ]]; then exit 0; fi
    fi

    local target_dir
    target_dir=$(get_destination_dir "${base_dir}" "${dest_choice}" "${custom_dir}" "Resize")

    # 4. Delegar al motor
    engine_process_files "${target_dir}" "Redimensionando imágenes" "Procesando" "" "" "${files[@]}"
}

# Ejecutar sólo si no se está cargando metadatos
if [[ -z "${METADATA_ONLY:-}" ]]; then
    action_resize "$@"
fi
