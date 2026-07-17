#!/usr/bin/env bash
# lib/dependencies.sh - Verificación de capabilities genérica

# Verifica si una herramienta está disponible en el sistema (PATH)
has_tool() {
    local cmd="$1"
    command -v "${cmd}" &> /dev/null
}

# Requiere una herramienta para continuar. 
# Si no está, muestra el mensaje de error y aborta la ejecución.
require_tool() {
    local cmd="$1"
    local error_msg="${2:-No se encontró la herramienta requerida: '${cmd}'.\n\nPor favor, instálala en tu sistema.}"

    if ! has_tool "${cmd}"; then
        dialog_error "${error_msg}"
        exit 1
    fi
}

# Wrapper específico para ImageMagick (ya que puede ser magick o convert)
require_imagemagick() {
    if has_tool "magick"; then
        return 0
    elif has_tool "convert"; then
        return 0
    else
        dialog_error "No se encontró ImageMagick en el sistema.\n\nPor favor, instala 'imagemagick' para usar esta herramienta."
        exit 1
    fi
}

# Obtiene el comando de ImageMagick a usar (magick si existe, sino convert)
get_imagemagick_cmd() {
    if has_tool "magick"; then
        echo "magick"
    else
        echo "convert"
    fi
}
