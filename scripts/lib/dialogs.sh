#!/usr/bin/env bash
# lib/dialogs.sh - Funciones de interfaz de usuario usando KDialog

# Muestra un mensaje de error
dialog_error() {
    kdialog --title "Dolphin Image Tools - Error" --error "$1" 2>/dev/null
}

# Muestra un mensaje informativo
dialog_info() {
    kdialog --title "Dolphin Image Tools" --msgbox "$1" 2>/dev/null
}

# Muestra una notificación pasiva (toast popup)
dialog_notify() {
    local msg="$1"
    local title="${2:-Dolphin Image Tools}"
    local delay="${3:-5}"
    kdialog --title "${title}" --passivepopup "${msg}" "${delay}" 2>/dev/null &
}

# Muestra el menú principal de herramientas (Dinámico)
dialog_main_menu() {
    local choice
    set +e
    choice=$(kdialog --title "Dolphin Image Tools" \
        --menu "Selecciona la acción a realizar:" \
        "$@" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# --- Opciones de Resize ---

# Muestra el menú para elegir tamaño de Resize
dialog_resize_size() {
    local choice
    set +e
    choice=$(kdialog --title "Redimensionar Imágenes" \
        --menu "Selecciona el tamaño deseado:" \
        "64x64" "64x64 píxeles" \
        "128x128" "128x128 píxeles" \
        "256x256" "256x256 píxeles" \
        "512x512" "512x512 píxeles" \
        "1024x1024" "1024x1024 píxeles" \
        "custom" "Personalizado..." 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# Solicita dimensiones personalizadas
dialog_resize_custom() {
    local width height keep_aspect=1
    set +e
    width=$(kdialog --title "Tamaño Personalizado" --inputbox "Ingrese el ancho (ej: 800):" 2>/dev/null)
    if [[ $? -ne 0 || -z "$width" ]]; then set -e; echo ""; return; fi

    height=$(kdialog --title "Tamaño Personalizado" --inputbox "Ingrese el alto (ej: 600):" 2>/dev/null)
    if [[ $? -ne 0 || -z "$height" ]]; then set -e; echo ""; return; fi

    kdialog --title "Tamaño Personalizado" --yesno "¿Mantener proporción de aspecto original?" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        keep_aspect=0
    fi
    set -e

    echo "${width}x${height} ${keep_aspect}"
}

# Pregunta por la carpeta destino
dialog_resize_destination() {
    local choice
    set +e
    choice=$(kdialog --title "Destino" \
        --menu "¿Dónde deseas guardar las imágenes procesadas?" \
        "overwrite" "Sobrescribir originales (CUIDADO)" \
        "subfolder" "Crear carpeta 'Resize' junto a originales" \
        "custom" "Elegir carpeta..." 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# Solicita seleccionar un directorio
dialog_select_directory() {
    local dir
    set +e
    dir=$(kdialog --title "Seleccionar carpeta destino" --getexistingdirectory "$1" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${dir}"
    else
        echo ""
    fi
}

# --- Opciones de Convert ---

# Muestra el menú de formatos para Convertir
dialog_convert_format() {
    local choice
    set +e
    choice=$(kdialog --title "Convertir Formato" \
        --menu "Selecciona el formato de salida:" \
        "webp" "WEBP (Recomendado para Web)" \
        "png" "PNG (Sin pérdida / Transparencia)" \
        "jpg" "JPG (Estándar comprimido)" \
        "avif" "AVIF (Alta compresión de nueva generación)" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# Solicita calidad para JPG/WEBP/AVIF
dialog_convert_quality() {
    local quality
    set +e
    quality=$(kdialog --title "Calidad de Compresión" \
        --inputbox "Ingrese la calidad (1-100):" "85" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${quality}"
    else
        echo ""
    fi
}

# Pregunta por la carpeta destino para conversión
dialog_convert_destination() {
    local choice
    set +e
    choice=$(kdialog --title "Destino de Conversión" \
        --menu "¿Dónde deseas guardar las imágenes convertidas?" \
        "same_dir" "En la misma carpeta (junto a los originales)" \
        "subfolder" "Crear carpeta 'Convert' junto a originales" \
        "custom" "Elegir carpeta..." 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# --- Opciones de Rembg ---

# Muestra advertencia sobre la inicialización de rembg (sólo una vez)
dialog_rembg_warning() {
    # Si ya se mostró antes, retornamos éxito inmediatamente
    if state_has "rembg_initialized"; then return 0; fi

    set +e
    kdialog --title "Eliminar Fondo (Rembg)" \
        --warningcontinuecancel "La primera ejecución de 'rembg' puede tardar unos segundos mientras se inicializa el modelo de IA.\n\n¿Deseas continuar?" 2>/dev/null
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        state_set "rembg_initialized"
    fi
    return ${status}
}

# Pregunta por la carpeta destino para Rembg
dialog_rembg_destination() {
    local choice
    set +e
    choice=$(kdialog --title "Destino de Rembg" \
        --menu "¿Dónde deseas guardar las imágenes sin fondo (PNG)?" \
        "subfolder" "Crear carpeta 'No-Background' junto a originales" \
        "custom" "Elegir carpeta..." 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# --- Opciones de Upscale ---

# Muestra el menú de selección de modelo
dialog_upscale_model() {
    local choice
    set +e
    choice=$(kdialog --title "Super-resolución (Waifu2x)" \
        --menu "Selecciona el tipo de imagen:" \
        "photo" "Fotografía Real (Real Photo)" \
        "anime" "Ilustración / Anime" \
        "artwork" "Arte 2D general" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# Muestra el menú de selección de escala (v1.1)
dialog_upscale_scale() {
    local choice
    set +e
    choice=$(kdialog --title "Super-resolución (Waifu2x)" \
        --menu "Selecciona el factor de escala:" \
        "2" "Escalar 2x" \
        "4" "Escalar 4x" \
        "8" "Escalar 8x (Doble pasada)" \
        "custom" "Factor personalizado (Ej: 300%)" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# Solicita factor personalizado para Upscale
dialog_upscale_custom() {
    local scale
    set +e
    scale=$(kdialog --title "Escala Personalizada" \
        --inputbox "Ingrese el porcentaje de escala deseado (ej: 300 para 300%):" "300" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${scale}"
    else
        echo ""
    fi
}

# Muestra el menú de reducción de ruido (denoise)
dialog_upscale_denoise() {
    local choice
    set +e
    choice=$(kdialog --title "Super-resolución (Waifu2x)" \
        --menu "Selecciona el nivel de reducción de ruido (Denoise):" \
        "none" "Ninguno" \
        "low" "Bajo" \
        "medium" "Medio" \
        "high" "Alto" \
        "max" "Máximo (Puede suavizar demasiado)" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        case "${choice}" in
            none) echo "-1" ;;
            low) echo "0" ;;
            medium) echo "1" ;;
            high) echo "2" ;;
            max) echo "3" ;;
            *) echo "-1" ;;
        esac
    else
        echo ""
    fi
}

# Muestra el menú de selección de formato de salida para Upscale
dialog_upscale_format() {
    local choice
    set +e
    choice=$(kdialog --title "Formato de Salida - Upscale" \
        --menu "Selecciona el formato final:" \
        "keep" "Mantener formato original" \
        "png" "PNG (Sin pérdida)" \
        "webp" "WEBP (Optimizado)" \
        "jpg" "JPG (Estándar comprimido)" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# Pregunta por la carpeta destino para Upscale
dialog_upscale_destination() {
    local choice
    set +e
    choice=$(kdialog --title "Destino de Super-resolución" \
        --menu "¿Dónde deseas guardar las imágenes reescaladas?" \
        "subfolder" "Crear carpeta 'Upscale' junto a originales" \
        "custom" "Elegir carpeta..." 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# --- Diálogos Avanzados Rembg++ ---

# Menú de selección de modelo para Rembg
dialog_rembg_model() {
    local choice
    set +e
    choice=$(kdialog --title "Modelo de IA - Rembg" \
        --menu "Selecciona el modelo de extracción:" \
        "u2net" "General (u2net)" \
        "u2net_human_seg" "Retrato Humano (u2net_human_seg)" \
        "isnet-anime" "Anime / Ilustración (isnet-anime)" \
        "isnet-general-use" "Alta Definición (isnet-general-use)" \
        "silueta" "Silueta (silueta)" \
        "u2net_cloth_seg" "Prendas/Ropa (u2net_cloth_seg)" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# Selección de formato de salida para Rembg
dialog_rembg_format() {
    local choice
    set +e
    choice=$(kdialog --title "Formato de Salida - Rembg" \
        --menu "Selecciona el formato final de la imagen:" \
        "png" "PNG (Recomendado - Transparencia)" \
        "webp" "WEBP (Compacto - Transparencia)" \
        "tiff" "TIFF (Sin compresión)" 2>/dev/null)
    local status=$?
    set -e

    if [[ ${status} -eq 0 ]]; then
        echo "${choice}"
    else
        echo ""
    fi
}

# Pregunta sobre Alpha Matting (suavizado de bordes)
dialog_rembg_matting() {
    set +e
    kdialog --title "Suavizado de Bordes" \
        --yesno "¿Deseas aplicar Alpha Matting para suavizar bordes complejos (cabello, texturas finas)?" 2>/dev/null
    local status=$?
    set -e
    
    # 0 = Sí, 1 = No
    if [[ ${status} -eq 0 ]]; then
        echo "1"
    else
        echo "0"
    fi
}
