#!/usr/bin/env bash
# Ejecuta las cuatro pruebas y guarda stdout/stderr en resultados/.
set -u

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$RAIZ/build/analizador"

mkdir -p "$RAIZ/resultados"

for archivo in "$RAIZ"/pruebas/*.txt; do
    nombre="$(basename "$archivo" .txt)"

    echo "====================================================================="
    echo "PRUEBA: $nombre"
    echo "Entrada: $(cat "$archivo")"
    echo "====================================================================="

    "$BIN" < "$archivo" > "$RAIZ/resultados/$nombre.out" 2> "$RAIZ/resultados/$nombre.err"
    estado=$?

    echo "--- tokens (stdout) ---"
    cat "$RAIZ/resultados/$nombre.out"
    echo "--- tablas / errores (stderr) ---"
    cat "$RAIZ/resultados/$nombre.err"
    echo "--- codigo de salida: $estado ---"
    echo
done
