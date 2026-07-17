#!/usr/bin/env bash
# scripts/image-tools.sh - Launcher, framework y utilidad doctor de Dolphin Image Tools (v1.0 Estabilizado)

set -euo pipefail

# Obtener la ruta del directorio del script actual de forma segura
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly ACTIONS_DIR="${SCRIPT_DIR}/actions"

# Asegurar carpetas comunes de binarios de usuario en el PATH (especialmente para entornos GUI de Dolphin)
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

# Cargar la suite completa de librerías compartidas
source "${LIB_DIR}/logging.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/config.sh"
source "${LIB_DIR}/dialogs.sh"
source "${LIB_DIR}/notify.sh"
source "${LIB_DIR}/filesystem.sh"
source "${LIB_DIR}/dependencies.sh"
source "${LIB_DIR}/progress.sh"
source "${LIB_DIR}/engine.sh"

# Inicializar configuración del usuario
config_load

# Obtiene la versión del binario de forma limpia
get_tool_version() {
    local tool="$1"
    if ! has_tool "${tool}"; then
        echo "No instalado"
        return
    fi
    case "${tool}" in
        magick)
            if has_tool "magick"; then
                magick -version 2>/dev/null | head -n1 | awk '{print $3}' || echo "Instalado"
            else
                convert -version 2>/dev/null | head -n1 | awk '{print $3}' || echo "Instalado"
            fi
            ;;
        rembg)
            # Intentar obtener versión desde pip
            pip show rembg 2>/dev/null | grep -i "Version:" | awk '{print $2}' || echo "Instalado"
            ;;
        waifu2x-ncnn-vulkan)
            echo "Instalado"
            ;;
        jpegoptim)
            jpegoptim --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "Instalado"
            ;;
        optipng)
            optipng --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "Instalado"
            ;;
        pngquant)
            pngquant --version 2>/dev/null | head -n1 | awk '{print $1}' || echo "Instalado"
            ;;
        cwebp)
            cwebp -version 2>/dev/null || echo "Instalado"
            ;;
        avifenc)
            avifenc --version 2>/dev/null | head -n1 | awk '{print $3}' || echo "Instalado"
            ;;
        *)
            echo "Instalado"
            ;;
    esac
}

main() {
    # 1. Modo Diagnóstico (Doctor CLI)
    if [[ "${1:-}" == "--doctor" ]]; then
        echo "=================================================="
        echo "           Dolphin Image Tools Doctor"
        echo "=================================================="
        echo ""
        
        # Telemetría de Sistema y KDE Plasma
        echo "Información del Sistema:"
        local plasma_ver
        plasma_ver=$(plasmashell --version 2>/dev/null || echo "Desconocido")
        local session_type="${XDG_SESSION_TYPE:-Desconocida}"
        local kde_ver="${KDE_SESSION_VERSION:-Desconocida}"
        
        echo "  Entorno : KDE Plasma (${plasma_ver})"
        echo "  Sesión  : ${session_type} (KDE Versión: ${kde_ver})"
        echo ""

        # Dependencias del Ecosistema
        echo "Dependencias de Binarios:"
        local tools=("magick" "rembg" "waifu2x-ncnn-vulkan" "jpegoptim" "optipng" "pngquant" "cwebp" "avifenc")
        for tool in "${tools[@]}"; do
            local ver
            ver=$(get_tool_version "${tool}")
            if [[ "${ver}" == "No instalado" ]]; then
                echo "  ✗ ${tool} : No instalado"
            else
                echo "  ✓ ${tool} : ${ver}"
            fi
        done
        echo ""

        # Descubrimiento de Plugins
        echo "Plugins encontrados en actions/:"
        for script in "${ACTIONS_DIR}"/*.sh; do
            [[ -f "${script}" ]] || continue
            local ACTION_ID=""
            local ACTION_NAME=""
            local ACTION_DEPENDENCIES=()
            local ACTION_VERSION="1.0"
            local ACTION_API="1"
            
            # Cargar metadatos del plugin
            METADATA_ONLY=1 source "${script}" &> /dev/null || true
            
            if [[ -n "${ACTION_ID}" ]]; then
                # Verificar compatibilidad de API
                if [[ "${ACTION_API}" != "1" ]]; then
                    echo "  ✗ ${ACTION_NAME} [Incompatible - Requiere API ${ACTION_API}]"
                    continue
                fi

                # Verificar si tiene las dependencias cubiertas
                local deps_ok=1
                for dep in "${ACTION_DEPENDENCIES[@]}"; do
                    if [[ "${dep}" == "magick" ]]; then
                        if ! has_tool "magick" && ! has_tool "convert"; then deps_ok=0; break; fi
                    elif ! has_tool "${dep}"; then
                        deps_ok=0
                        break
                    fi
                done
                
                if [[ ${deps_ok} -eq 1 ]]; then
                    echo "  ✓ ${ACTION_NAME} (v${ACTION_VERSION}, API ${ACTION_API}) [Activo]"
                else
                    echo "  ⚠ ${ACTION_NAME} (v${ACTION_VERSION}, API ${ACTION_API}) [Inactivo - Falta Dependencia]"
                fi
            fi
        done
        echo ""

        # Archivos del Framework
        echo "Rutas del Framework:"
        echo "  Configuración : ${CONFIG_FILE}"
        echo "  Logs de ejec. : ${LOG_FILE}"
        echo "=================================================="
        exit 0
    fi

    # Verificar que se hayan pasado argumentos
    if [[ $# -eq 0 ]]; then
        dialog_error "No se ha proporcionado ninguna imagen."
        exit 1
    fi

    # Escanear plugins de acciones dinámicamente
    local action_ids=()
    local action_names=()
    local action_scripts=()
    
    log_info "Escaneando plugins de acciones en: ${ACTIONS_DIR}"

    for script in "${ACTIONS_DIR}"/*.sh; do
        [[ -f "${script}" ]] || continue

        # Inicializar variables de metadatos antes de cargar el script
        local ACTION_ID=""
        local ACTION_NAME=""
        local ACTION_DESCRIPTION=""
        local ACTION_DEPENDENCIES=()
        local ACTION_VERSION="1.0"
        local ACTION_API="1"

        # Sourcing silencioso limitado a lectura de metadatos
        METADATA_ONLY=1 source "${script}" &> /dev/null || true

        if [[ -z "${ACTION_ID}" || -z "${ACTION_NAME}" ]]; then
            log_warn "Plugin omitido por falta de metadatos obligatorios (ACTION_ID/ACTION_NAME): $(basename "${script}")"
            continue
        fi

        # Validar compatibilidad de API con el Framework (v1.0 soporta API 1)
        if [[ "${ACTION_API}" != "1" ]]; then
            log_warn "Plugin '${ACTION_ID}' omitido. API de plugin no soportada por el framework (requerida: ${ACTION_API}, soportada: 1)."
            continue
        fi

        # Comprobar dependencias del plugin
        local deps_satisfied=1
        for dep in "${ACTION_DEPENDENCIES[@]}"; do
            # Tratamiento especial para ImageMagick (magick o convert)
            if [[ "${dep}" == "magick" ]]; then
                if ! has_tool "magick" && ! has_tool "convert"; then
                    deps_satisfied=0
                    log_warn "Acción '${ACTION_ID}' desactivada. Falta dependencia: magick (imagemagick)"
                    break
                fi
            elif ! has_tool "${dep}"; then
                deps_satisfied=0
                log_warn "Acción '${ACTION_ID}' desactivada. Falta dependencia: ${dep}"
                break
            fi
        done

        # Registrar el plugin si tiene todas las dependencias
        if [[ ${deps_satisfied} -eq 1 ]]; then
            action_ids+=("${ACTION_ID}")
            action_names+=("${ACTION_NAME}")
            action_scripts+=("${script}")
            log_info "Plugin registrado con éxito: ${ACTION_ID} (v${ACTION_VERSION}, API ${ACTION_API})"
        fi
    done

    # Si no se encontraron acciones disponibles en el sistema
    if [[ ${#action_ids[@]} -eq 0 ]]; then
        dialog_error "No hay herramientas de imagen disponibles en el sistema.\n\nPor favor, instala dependencias como ImageMagick, rembg o waifu2x."
        exit 1
    fi

    # Preparar pares de argumentos para KDialog
    local menu_args=()
    local i
    for ((i=0; i<${#action_ids[@]}; i++)); do
        menu_args+=("${action_ids[i]}" "${action_names[i]}")
    done

    # Mostrar menú dinámico
    local selected_action
    selected_action=$(dialog_main_menu "${menu_args[@]}")

    if [[ -z "${selected_action}" ]]; then
        exit 0
    fi

    # Resolver script de la acción elegida
    local target_script=""
    for ((i=0; i<${#action_ids[@]}; i++)); do
        if [[ "${action_ids[i]}" == "${selected_action}" ]]; then
            target_script="${action_scripts[i]}"
            break
        fi
    done

    if [[ -n "${target_script}" && -f "${target_script}" ]]; then
        log_info "Ejecutando acción seleccionada: '${selected_action}' desde '${target_script}'"
        
        # Limpiar cualquier residuo de hooks anteriores antes de cargar la nueva acción
        if [[ -n "${ACTION_PROCESS:-}" ]]; then unset -f "${ACTION_PROCESS}"; fi
        if [[ -n "${ACTION_BEFORE:-}" ]]; then unset -f "${ACTION_BEFORE}"; fi
        if [[ -n "${ACTION_AFTER:-}" ]]; then unset -f "${ACTION_AFTER}"; fi

        # Limpiar variables de metadatos globales del launcher
        unset ACTION_PROCESS ACTION_BEFORE ACTION_AFTER ACTION_ID ACTION_NAME ACTION_VERSION ACTION_API ACTION_DEPENDENCIES

        # Cargar el código completo de la acción (el plugin define sus funciones específicas)
        source "${target_script}" "$@"
    else
        dialog_error "Error al intentar localizar el script para la acción seleccionada."
        exit 1
    fi
}

main "$@"
