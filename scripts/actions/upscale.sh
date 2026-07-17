#!/usr/bin/env bash
# actions/upscale.sh - Lógica para super-resolución de imágenes (Upscale++ v1.1)

# Metadatos del plugin
ACTION_ID="upscale"
ACTION_NAME="Escalar sin perder calidad (Upscale)"
ACTION_DESCRIPTION="Super-resolución de imágenes (2x, 4x, 8x y personalizado) con waifu2x-ncnn-vulkan"
ACTION_DEPENDENCIES=("waifu2x-ncnn-vulkan")
ACTION_VERSION="1.1"
ACTION_API="1"

# Contrato estándar de ejecución
ACTION_PROCESS="upscale_process_file"
ACTION_BEFORE="upscale_before_process"

_upscale_scale="2"
_custom_percentage=""
_upscale_denoise="-1"
_upscale_model_name="models-cunet"
_upscale_format="keep"

upscale_before_process() {
    dialog_notify "Inicializando super-resolución waifu2x...\nEl procesamiento por lotes puede tardar unos momentos."
}

upscale_process_file() {
    local in="$1"
    local out="$2"
    local tmp_dir="${HOME}/.cache/dolphin-image-tools"
    mkdir -p "${tmp_dir}"
    
    local out_ext="${out##*.}"
    # Generar un archivo de salida temporal único para escritura atómica
    local final_tmp="${tmp_dir}/atomic_upscale_out.${out_ext}"
    
    local run_scale="${_upscale_scale}"
    local final_resize_pct=""
    
    # 1. Resolver escala customizada
    if [[ "${_upscale_scale}" == "custom" ]]; then
        local pct="${_custom_percentage}"
        if [[ ${pct} -le 200 ]]; then
            run_scale="2"
        elif [[ ${pct} -le 400 ]]; then
            run_scale="4"
        else
            run_scale="8"
        fi
        final_resize_pct="${pct}%"
    fi
    
    local status=0
    local magick_cmd
    magick_cmd=$(get_imagemagick_cmd)
    
    # 2. Ejecutar super-resolución y redimensionamiento
    if [[ "${run_scale}" == "8" ]]; then
        # Doble pasada: 4x y luego 2x
        local tmp_file1="${tmp_dir}/temp_upscale_1.png"
        waifu2x-ncnn-vulkan -i "${in}" -o "${tmp_file1}" -s 4 -n "${_upscale_denoise}" -m "${_upscale_model_name}" || status=$?
        
        if [[ ${status} -eq 0 ]]; then
            local tmp_file2="${tmp_dir}/temp_upscale_2.png"
            
            if [[ -n "${final_resize_pct}" ]]; then
                # Requiere redimensión final con ImageMagick escribiendo al temp final
                waifu2x-ncnn-vulkan -i "${tmp_file1}" -o "${tmp_file2}" -s 2 -n "${_upscale_denoise}" -m "${_upscale_model_name}" || status=$?
                if [[ ${status} -eq 0 ]]; then
                    ${magick_cmd} "${tmp_file2}" -resize "${final_resize_pct}" "${final_tmp}" || status=$?
                fi
            else
                # Doble pasada pura a 8x sin recorte escribiendo al temp final
                waifu2x-ncnn-vulkan -i "${tmp_file1}" -o "${final_tmp}" -s 2 -n "${_upscale_denoise}" -m "${_upscale_model_name}" || status=$?
            fi
            rm -f "${tmp_file2}"
        fi
        rm -f "${tmp_file1}"
    else
        # Pasada única (2x o 4x)
        if [[ -n "${final_resize_pct}" ]]; then
            # Requiere ajuste final con ImageMagick escribiendo al temp final
            local tmp_file1="${tmp_dir}/temp_upscale_single.png"
            waifu2x-ncnn-vulkan -i "${in}" -o "${tmp_file1}" -s "${run_scale}" -n "${_upscale_denoise}" -m "${_upscale_model_name}" || status=$?
            if [[ ${status} -eq 0 ]]; then
                ${magick_cmd} "${tmp_file1}" -resize "${final_resize_pct}" "${final_tmp}" || status=$?
            fi
            rm -f "${tmp_file1}"
        else
            # Pasada única pura escribiendo al temp final
            waifu2x-ncnn-vulkan -i "${in}" -o "${final_tmp}" -s "${run_scale}" -n "${_upscale_denoise}" -m "${_upscale_model_name}" || status=$?
        fi
    fi
    
    # 3. Validación y movimiento atómico final
    if [[ ${status} -eq 0 && -f "${final_tmp}" ]]; then
        # Comprobar la integridad real del archivo de imagen generado
        if ${magick_cmd} identify "${final_tmp}" &> /dev/null; then
            mv -f "${final_tmp}" "${out}"
            return 0
        else
            rm -f "${final_tmp}"
            return 1
        fi
    else
        rm -f "${final_tmp}"
        return 1
    fi
}

find_waifu2x_model_dir() {
    local candidates=(
        "/usr/share/waifu2x-ncnn-vulkan"
        "/usr/local/share/waifu2x-ncnn-vulkan"
        "/opt/waifu2x-ncnn-vulkan"
        "${HOME}/.local/share/waifu2x-ncnn-vulkan"
    )

    for dir in "${candidates[@]}"; do
        if [[ -d "${dir}/models-cunet" ]]; then
            echo "${dir}"
            return 0
        fi
    done

    return 1
}

action_upscale() {
    local files=("$@")

    # 1. Verificar dependencias
    require_tool "waifu2x-ncnn-vulkan" "No se encontró 'waifu2x-ncnn-vulkan' en el sistema.\n\nPor favor, instala 'waifu2x-ncnn-vulkan' para usar la super-resolución."

    local waifu_dir
    waifu_dir=$(find_waifu2x_model_dir || true)
    if [[ -z "${waifu_dir}" ]]; then
        dialog_error "No se encontró la carpeta de modelos de waifu2x en las rutas estándar del sistema."
        exit 1
    fi

    # 2. Solicitar Modelo
    local model_choice
    model_choice=$(dialog_upscale_model)
    if [[ -z "${model_choice}" ]]; then exit 0; fi
    
    # Mapeo del modelo con ruta absoluta
    if [[ "${model_choice}" == "photo" ]]; then
        _upscale_model_name="${waifu_dir}/models-upconv_7_photo"
    elif [[ "${model_choice}" == "anime" ]]; then
        _upscale_model_name="${waifu_dir}/models-cunet"
    else
        _upscale_model_name="${waifu_dir}/models-upconv_7_anime_style_art_rgb"
    fi

    # 3. Solicitar Factor de Escala
    _upscale_scale=$(dialog_upscale_scale)
    if [[ -z "${_upscale_scale}" ]]; then exit 0; fi

    # Solicitar escala personalizada si se requiere
    if [[ "${_upscale_scale}" == "custom" ]]; then
        _custom_percentage=$(dialog_upscale_custom)
        if [[ -z "${_custom_percentage}" ]]; then exit 0; fi
    fi

    # 4. Solicitar Nivel de Denoise
    _upscale_denoise=$(dialog_upscale_denoise)
    if [[ -z "${_upscale_denoise}" ]]; then exit 0; fi

    # 5. Solicitar Formato de Salida
    _upscale_format=$(dialog_upscale_format)
    if [[ -z "${_upscale_format}" ]]; then exit 0; fi

    # 6. Solicitar Destino
    local dest_choice
    dest_choice=$(dialog_upscale_destination)
    if [[ -z "${dest_choice}" ]]; then exit 0; fi

    local base_dir
    base_dir=$(dirname "${files[0]}")

    local custom_dir=""
    if [[ "${dest_choice}" == "custom" ]]; then
        custom_dir=$(dialog_select_directory "${base_dir}")
        if [[ -z "${custom_dir}" ]]; then exit 0; fi
    fi

    local target_dir
    target_dir=$(get_destination_dir "${base_dir}" "${dest_choice}" "${custom_dir}" "Upscale")

    # Mapear el formato al engine
    local force_extension=""
    if [[ "${_upscale_format}" != "keep" ]]; then
        force_extension="${_upscale_format}"
    fi

    # Calcular sufijo de escala
    local suffix_scale="_${_upscale_scale}x"
    if [[ "${_upscale_scale}" == "custom" ]]; then
        suffix_scale="_${_custom_percentage}pct"
    fi

    # 7. Delegar al motor
    engine_process_files "${target_dir}" "Super-resolución" "Escalando" "${suffix_scale}" "${force_extension}" "${files[@]}"
}

# Ejecutar sólo si no se está cargando metadatos
if [[ -z "${METADATA_ONLY:-}" ]]; then
    action_upscale "$@"
fi
