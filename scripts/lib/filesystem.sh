#!/usr/bin/env bash
# lib/filesystem.sh - Funciones auxiliares para manejo de archivos y directorios

# Obtiene la ruta del directorio de destino basándose en la elección del usuario
# $1: Ruta base (normalmente el directorio del primer archivo)
# $2: Elección (overwrite, subfolder, custom)
# $3: Carpeta personalizada (opcional, requerida si elección es custom)
# $4: Nombre del subdirectorio (ej: "Resize")
# Devuelve por stdout la ruta destino.
get_destination_dir() {
    local base_dir="$1"
    local choice="$2"
    local custom_dir="${3:-}"
    local sub_name="${4:-Resize}"
    
    local dest_dir=""
    
    case "${choice}" in
        "overwrite")
            dest_dir="${base_dir}"
            ;;
        "subfolder")
            dest_dir="${base_dir}/${sub_name}"
            # Crear la carpeta si no existe
            mkdir -p "${dest_dir}"
            ;;
        "custom")
            if [[ -n "${custom_dir}" ]]; then
                dest_dir="${custom_dir}"
            else
                dest_dir="${base_dir}"
            fi
            ;;
    esac
    
    echo "${dest_dir}"
}

# Obtiene la extensión de un archivo (en minúsculas)
# $1: Ruta del archivo
get_extension() {
    local filename
    filename=$(basename "$1")
    echo "${filename##*.}" | tr '[:upper:]' '[:lower:]'
}
