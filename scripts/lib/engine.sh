#!/usr/bin/env bash
# lib/engine.sh - Motor de ejecución centralizado para Dolphin Image Tools (v1.0 Estabilizado)

# Ejecuta el bucle principal de procesamiento
# Argumentos:
# $1: Directorio destino base
# $2: Título de la acción (ej: "Convirtiendo imágenes")
# $3: Prefijo para la barra de progreso (ej: "Convirtiendo")
# $4: Sufijo extra a añadir al nombre final (opcional, ej: "_nobg")
# $5: Extensión forzada para el archivo final (opcional, ej: "png")
# $6...: Lista de archivos a procesar
engine_process_files() {
    local target_dir="$1"
    local action_title="$2"
    local progress_prefix="$3"
    local suffix="${4:-}"
    local force_ext="${5:-}"
    shift 5
    local files=("$@")
    local total_files=${#files[@]}

    if [[ ${total_files} -eq 0 ]]; then
        log_warn "engine_process_files: Se llamó con un array de archivos vacío."
        return 0
    fi

    # Comprobar que el plugin declaró la función de proceso requerida
    if [[ -z "${ACTION_PROCESS:-}" ]]; then
        log_error "Error crítico: El plugin no definió la variable ACTION_PROCESS."
        dialog_error "El plugin seleccionado no está bien configurado (falta ACTION_PROCESS)."
        return 1
    fi

    if ! declare -f "${ACTION_PROCESS}" &> /dev/null; then
        log_error "Error crítico: La función '${ACTION_PROCESS}' no está definida."
        dialog_error "El plugin seleccionado no definió la función de procesamiento requerida."
        return 1
    fi

    # 1. Ejecutar hook before_process (si está definido en los metadatos)
    if [[ -n "${ACTION_BEFORE:-}" ]] && declare -f "${ACTION_BEFORE}" &> /dev/null; then
        log_info "Ejecutando hook del plugin: ${ACTION_BEFORE}"
        local before_status=0
        ${ACTION_BEFORE} "${target_dir}" "${files[@]}" || before_status=$?
        if [[ ${before_status} -ne 0 ]]; then
            log_error "El hook ${ACTION_BEFORE} falló con código ${before_status}. Abortando procesamiento."
            dialog_error "Error crítico al inicializar la acción '${action_title}'."
            return 1
        fi
    fi

    # 2. Iniciar barra de progreso
    local dbus_ref
    dbus_ref=$(progress_start "${action_title}" "Iniciando..." "${total_files}" 2>/dev/null || echo "dbus_dummy")

    local success_count=0
    local fail_count=0
    local current_step=0

    # 3. Bucle principal de ejecución usando el contrato estándar mapeado en ACTION_PROCESS
    for file in "${files[@]}"; do
        current_step=$((current_step + 1))
        local filename
        filename=$(basename "${file}")

        # Resolver el nombre final del archivo y su extensión
        local base_name="${filename%.*}"
        local ext="${filename##*.}"
        if [[ -n "${force_ext}" ]]; then
            ext="${force_ext}"
        fi
        
        local dest_filename="${base_name}${suffix}.${ext}"
        local dest_file="${target_dir}/${dest_filename}"

        # Evitar sobrescribir el archivo de origen si coincide ruta y extensión
        if [[ "${file}" == "${dest_file}" ]]; then
            dest_file="${target_dir}/${base_name}${suffix}_processed.${ext}"
        fi

        # Actualizar UI de progreso
        progress_update "${dbus_ref}" "${current_step}" "${progress_prefix}: ${filename}..." &> /dev/null

        # Registrar inicio de procesamiento en log
        log_info "Procesando archivo: '${file}' -> '${dest_file}' usando '${ACTION_PROCESS}'"

        # Ejecutar la función mapeada en la acción redirigiendo salida y errores al log global del framework
        local status=0
        ${ACTION_PROCESS} "${file}" "${dest_file}" &>> "${LOG_FILE}" || status=$?

        # Validación robusta de la API v1.0: el archivo debe existir y tener tamaño mayor que 0
        if [[ ${status} -eq 0 && -s "${dest_file}" ]]; then
            success_count=$((success_count + 1))
            log_debug "Procesado exitosamente: '${file}'"
        else
            # Si el comando retornó 0 pero el archivo no existe o está vacío, marcar como fallo
            if [[ ${status} -eq 0 ]]; then
                status=1
            fi
            fail_count=$((fail_count + 1))
            log_error "Error al procesar: '${file}' (Código de salida: ${status}, Archivo destino válido: N)"
        fi
    done

    # Finalizar progreso
    progress_close "${dbus_ref}" &> /dev/null

    # 4. Ejecutar hook after_process (si está definido en los metadatos)
    if [[ -n "${ACTION_AFTER:-}" ]] && declare -f "${ACTION_AFTER}" &> /dev/null; then
        log_info "Ejecutando hook del plugin: ${ACTION_AFTER}"
        ${ACTION_AFTER} "${target_dir}" &> /dev/null || true
    fi

    # Resumen final
    local msg="Proceso completado.\n\n"
    msg+="Imágenes procesadas exitosamente: ${success_count}\n"
    if [[ ${fail_count} -gt 0 ]]; then
        msg+="Errores: ${fail_count}\n"
    fi
    msg+="Destino: ${target_dir}"

    log_info "Fin de procesamiento. Exitosos: ${success_count}, Errores: ${fail_count}. Destino: ${target_dir}"

    dialog_info "${msg}"
}
