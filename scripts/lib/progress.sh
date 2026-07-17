#!/usr/bin/env bash
# lib/progress.sh - Interfaz de progreso (Versión Dummy temporal para robustez)
# Abstrae la barra de progreso para evitar fallos con D-Bus / qdbus en distintas versiones de Plasma.

# Inicia la barra de progreso
# Imprime (stdout) una referencia dummy
progress_start() {
    # Retorna un identificador dummy
    echo "dummy_ref"
}

# Actualiza la barra de progreso
# Envía texto a stderr para depuración sin bloquear el stdout de las funciones
progress_update() {
    local dbus_ref="$1"
    local step="$2"
    local text="${3:-}"
    
    # Imprimir en la salida de error estándar para no contaminar stdout
    echo "[Progreso] Paso ${step}: ${text}" >&2
}

# Cierra la barra de progreso
progress_close() {
    echo "[Progreso] Finalizado." >&2
}
