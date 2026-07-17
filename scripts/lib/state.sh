#!/usr/bin/env bash
# lib/state.sh - Gestión de estado y caché persistente

readonly CACHE_DIR="${HOME}/.cache/dolphin-image-tools"

# Crea el directorio de caché si no existe
_ensure_cache_dir() {
    if [[ ! -d "${CACHE_DIR}" ]]; then
        mkdir -p "${CACHE_DIR}"
    fi
}

# Verifica si un flag de estado existe
# Devuelve 0 (éxito) si existe, 1 si no.
state_has() {
    local flag_name="$1"
    _ensure_cache_dir
    [[ -f "${CACHE_DIR}/${flag_name}" ]]
}

# Establece un flag de estado
state_set() {
    local flag_name="$1"
    _ensure_cache_dir
    touch "${CACHE_DIR}/${flag_name}"
}

# Elimina un flag de estado
state_clear() {
    local flag_name="$1"
    rm -f "${CACHE_DIR}/${flag_name}"
}
