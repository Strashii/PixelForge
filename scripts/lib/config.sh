#!/usr/bin/env bash
# lib/config.sh - Configuración persistente del usuario

readonly CONFIG_FILE="${HOME}/.config/dolphin-image-tools/config.conf"

# Valores por defecto
JPEG_QUALITY="85"
WEBP_QUALITY="85"
DEFAULT_OUTPUT="subfolder"
DEFAULT_UPSCALE_MODEL="anime"
SHOW_FIRST_RUN_WARNINGS="true"

_ensure_config_file() {
    local config_dir
    config_dir=$(dirname "${CONFIG_FILE}")
    if [[ ! -d "${config_dir}" ]]; then
        mkdir -p "${config_dir}"
    fi

    if [[ ! -f "${CONFIG_FILE}" ]]; then
        # Escribir defaults
        {
            echo "# Configuración de Dolphin Image Tools"
            echo "JPEG_QUALITY=\"85\""
            echo "WEBP_QUALITY=\"85\""
            echo "DEFAULT_OUTPUT=\"subfolder\""
            echo "DEFAULT_UPSCALE_MODEL=\"anime\""
            echo "SHOW_FIRST_RUN_WARNINGS=\"true\""
        } > "${CONFIG_FILE}"
    fi
}

# Carga la configuración del usuario
config_load() {
    _ensure_config_file
    source "${CONFIG_FILE}"
}

# Retorna el valor de una clave de configuración
config_get() {
    local key="$1"
    # Cargar si no se ha cargado (por seguridad)
    config_load
    echo "${!key}"
}

# Modifica o añade un parámetro de configuración de forma segura en Bash puro
config_set() {
    local key="$1"
    local val="$2"
    _ensure_config_file

    local tmp
    tmp=$(mktemp)
    local matched=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^${key}= ]]; then
            echo "${key}=\"${val}\"" >> "${tmp}"
            matched=1
        else
            echo "${line}" >> "${tmp}"
        fi
    done < "${CONFIG_FILE}"

    if [[ ${matched} -eq 0 ]]; then
        echo "${key}=\"${val}\"" >> "${tmp}"
    fi

    mv "${tmp}" "${CONFIG_FILE}"
    
    # Recargar en el entorno de ejecución actual
    source "${CONFIG_FILE}"
}
