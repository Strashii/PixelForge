#!/usr/bin/env bash
# lib/logging.sh - Registro cronológico y depuración

readonly LOG_FILE="${HOME}/.cache/dolphin-image-tools/execution.log"

_ensure_log_dir() {
    local log_dir
    log_dir=$(dirname "${LOG_FILE}")
    if [[ ! -d "${log_dir}" ]]; then
        mkdir -p "${log_dir}"
    fi
}

# Registra un mensaje con nivel
# $1: Nivel (DEBUG, INFO, WARNING, ERROR)
# $2: Mensaje
log_msg() {
    local level="$1"
    local msg="$2"
    _ensure_log_dir

    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Escribir al archivo de log
    echo "[${timestamp}] [${level}] ${msg}" >> "${LOG_FILE}"
}

log_debug() { log_msg "DEBUG" "$1"; }
log_info() { log_msg "INFO" "$1"; }
log_warn() { log_msg "WARNING" "$1"; }
log_error() { log_msg "ERROR" "$1"; }
