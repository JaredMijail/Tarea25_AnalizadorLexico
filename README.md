# Tarea 25 — Analizador léxico FLEX (estructura `if`)

Basado en la Figura 3.23, página 166, de Aho, Lam, Sethi y Ullman,
*Compilers: Principles, Techniques, and Tools*, 2.ª edición.

## Compilar y ejecutar

```bash
cd "/home/kolmogorov/Documents/GitHub/UNAL/Tarea25_AnalizadorLexico"
make
make test
```

Ejecución individual:

```bash
./build/analizador < pruebas/03_condicional.txt
```

## 1. Constantes manifiestas

```c
#define RELOP     400
#define KW        300
#define ID         10
#define NUMBER     11
#define TOK_ERROR 500

#define LT 1   /* <  */
#define LE 2   /* <= */
#define EQ 3   /* =  */
#define NE 4   /* <> */
#define GT 5   /* >  */
#define GE 6   /* >= */

#define IF    7   /* if   */
#define THEN  8   /* then */
#define ELSE  9   /* else */
```

Las palabras reservadas se agrupan en la categoría `KW` (300); el elemento
constitutivo se devuelve en `yylval` (`IF`, `THEN`, `ELSE`), igual que `RELOP`
devuelve `LT`, `LE`, etc.

## 2. Tablas de símbolos

Se usan dos tablas independientes, una para `ID` y otra para `NUMBER`:

```c
struct symtab {
    char identifiers[SIZE][MAX_LEX];
    int  totalID;
    char numbers[SIZE][MAX_LEX];
    int  totalNum;
};
```

`InstallID` e `InstallNum` llaman a `instalar`, que:

1. busca el lexema con `strcmp`;
2. si ya existe, devuelve la misma posición (no lo duplica);
3. si no existe, lo copia al final de la tabla;
4. devuelve la posición **1-based** (`1` = primera entrada).

Por eso `yylval` para `ID`/`NUMBER` es la posición en su tabla, no el valor
`10`/`11` de la categoría.

## 3. Correcciones al código inicial

- `LT`, `LE`, etc. eran variables `int`; ahora son constantes `#define`.
- `symtab` se declaraba como arreglo de estructuras y se usaba con `->`; ahora
  es una sola estructura global.
- `installNUM` guardaba en `identifiers`; ahora guarda en `numbers`.
- Las funciones guardaban en el índice `0` pero devolvían `1`: se corrigió el
  desplazamiento. Ahora la posición devuelta corresponde al índice + 1.
- Se agregó búsqueda previa: un identificador repetido reutiliza su posición
  (antes crecía la tabla con duplicados).
- Se corrigió `">"` que retornaba `NE`; ahora retorna `GT`.
- Se agregó `"<>"` para `NE`.
- Se agregó `%option noyywrap` y el ciclo `while (yylex() != 0)`; antes `main`
  solo leía el primer token.
- Se agregó una regla para caracteres no reconocidos (error léxico).

## 4. Pruebas

### Prueba 1 — Asignación

Entrada: `text3 = 3`

```text
token: 10, yylval: 1, text: text3
token: 400, yylval: 3, text: =
token: 11, yylval: 1, text: 3
```

Tablas: `text3` en ID posición 1; `3` en NUMBER posición 1.

### Prueba 2 — Comparación

Entrada: `5 < 30`

```text
token: 11, yylval: 1, text: 5
token: 400, yylval: 1, text: <
token: 11, yylval: 2, text: 30
```

`<` retorna `RELOP` (400) con `yylval = LT` (1). Los números quedan en las
posiciones 1 y 2 de la tabla NUMBER.

### Prueba 3 — Condicional

Entrada: `if text2 == text3 else text4`

```text
token: 300, yylval: 7, text: if
token: 10, yylval: 1, text: text2
token: 400, yylval: 3, text: =
token: 400, yylval: 3, text: =
token: 10, yylval: 2, text: text3
token: 300, yylval: 9, text: else
token: 10, yylval: 3, text: text4
```

Tabla ID: 1 = `text2`, 2 = `text3`, 3 = `text4`.

> Nota: en la imagen de referencia aparecen 4, 5 y 6 porque esa ejecución
> conservaba entradas anteriores en la tabla (o el contador no estaba
> inicializado). En una ejecución limpia las posiciones empiezan en 1; lo
> importante es que sean consecutivas y que un lexema repetido reutilice su
> posición.

### Prueba 4 — No duplicación en la tabla

Entrada: `if x = x then x = x else x = x`

Las seis apariciones de `x` retornan `yylval: 1` y en la tabla ID queda una
sola entrada: `posicion 1: x`. También se verifican `THEN` (8) y `ELSE` (9).

## 5. Archivos

```text
Tarea25_AnalizadorLexico/
├── lexer.l
├── Makefile
├── README.md
└── pruebas/
    ├── 01_asignacion.txt
    ├── 02_comparacion.txt
    ├── 03_condicional.txt
    ├── 04_duplicados.txt
    └── ejecutar.sh
```

Las salidas de `make test` se guardan en `resultados/`.
