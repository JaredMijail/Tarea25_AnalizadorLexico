/* =====================================================================
 * Tarea 25 - Analizador lexico FLEX
 * Estructura de seleccion (if) - Aho et al., Figura 3.23, p. 166
 *
 * Categorias:
 *   KW      (300)  if | then | else       yylval = IF | THEN | ELSE
 *   ID      (10)   identificador          yylval = posicion en tabla ID
 *   NUMBER  (11)   numero                 yylval = posicion en tabla NUM
 *   RELOP   (400)  < | <= | = | <> | > | >=
 *                                         yylval = LT | LE | EQ | NE | GT | GE
 * ===================================================================== */

%{
#include <stdio.h>
#include <string.h>

/* ------------------- Constantes manifiestas ----------------------- */
#define SIZE     100        /* capacidad de cada tabla de simbolos  */
#define MAX_LEX  100        /* longitud maxima de un lexema         */

/* Categorias lexicas: valor que retorna yylex() */
#define RELOP     400
#define KW        300
#define ID         10
#define NUMBER     11
#define TOK_ERROR 500

/* Elementos constitutivos de RELOP (valores de yylval) */
#define LT 1   /* <  */
#define LE 2   /* <= */
#define EQ 3   /* =  */
#define NE 4   /* <> */
#define GT 5   /* >  */
#define GE 6   /* >= */

/* Elementos constitutivos de KW (valores de yylval) */
#define IF    7   /* if   */
#define THEN  8   /* then */
#define ELSE  9   /* else */

/* --------------------- Variables globales ------------------------- */
int yylval;               /* elemento constitutivo o posicion en tabla */
int linea = 1;            /* linea actual, para reportar errores       */
int errores = 0;          /* cantidad de errores lexicos               */

/* --------------------- Tablas de simbolos ------------------------- */
struct symtab {
    char identifiers[SIZE][MAX_LEX];
    int  totalID;
    char numbers[SIZE][MAX_LEX];
    int  totalNum;
};

static struct symtab tabla;

/* Funciones pedidas en el enunciado */
int InstallID(const char *id);
int InstallNum(const char *numero);

/* Auxiliares */
static int instalar(char tabla[][MAX_LEX], int *total, const char *lexema);
static void imprimirTablas(void);
%}

%option noyywrap nounput noinput

/* --------------------- Definiciones regulares --------------------- */
letter      [A-Za-z]
digit       [0-9]
id          {letter}({letter}|{digit})*
number      {digit}+(\.{digit}+)?([Ee][+-]?{digit}+)?

%%

    /* Espacios: no generan token. El salto de linea se cuenta aparte. */
[ \t\r]+     { /* ignorar */ }
\n           { linea++; }

    /* Palabras reservadas: todas retornan la categoria KW.
     * Van antes de {id}; ademas, flex aplica la regla de la
     * coincidencia mas larga ("ifx" se reconoce como ID). */
"if"         { yylval = IF;   return KW; }
"then"       { yylval = THEN; return KW; }
"else"       { yylval = ELSE; return KW; }

    /* Identificadores: yylval = posicion (1-based) en la tabla ID */
{id}         { yylval = InstallID(yytext);
               return (yylval > 0) ? ID : TOK_ERROR; }

    /* Numeros: yylval = posicion (1-based) en la tabla NUMBER */
{number}     { yylval = InstallNum(yytext);
               return (yylval > 0) ? NUMBER : TOK_ERROR; }

    /* Operadores relacionales */
"<"          { yylval = LT; return RELOP; }
"<="         { yylval = LE; return RELOP; }
"="          { yylval = EQ; return RELOP; }
"<>"         { yylval = NE; return RELOP; }
">"          { yylval = GT; return RELOP; }
">="         { yylval = GE; return RELOP; }

    /* Cualquier otro caracter es un error lexico */
.            {
                fprintf(stderr,
                        "Error lexico en la linea %d: caracter no reconocido '%s'\n",
                        linea, yytext);
                errores++;
                return TOK_ERROR;
             }

%%

/* =====================================================================
 * Busca un lexema en una tabla. Retorna el indice 0-based o -1.
 * ===================================================================== */
static int buscar(char tabla[][MAX_LEX], int total, const char *lexema)
{
    int i;

    for (i = 0; i < total; i++) {
        if (strcmp(tabla[i], lexema) == 0)
            return i;
    }
    return -1;
}

/* =====================================================================
 * Instala un lexema si no existe y retorna su posicion 1-based.
 * Si ya existe, NO lo duplica: retorna la posicion que ya tenia.
 * Retorna 0 si la tabla esta llena o el lexema es demasiado largo.
 * ===================================================================== */
static int instalar(char tabla[][MAX_LEX], int *total, const char *lexema)
{
    int pos;
    int n;

    pos = buscar(tabla, *total, lexema);
    if (pos >= 0)
        return pos + 1;                 /* ya estaba: misma posicion */

    if (*total >= SIZE) {
        fprintf(stderr, "Error: tabla de simbolos llena (%d entradas)\n", SIZE);
        errores++;
        return 0;
    }

    n = snprintf(tabla[*total], MAX_LEX, "%s", lexema);
    if (n < 0 || n >= MAX_LEX) {
        fprintf(stderr, "Error: lexema demasiado largo '%s'\n", lexema);
        errores++;
        return 0;
    }

    (*total)++;
    return *total;                       /* posicion 1-based */
}

/* Instala un identificador en la tabla de ID. */
int InstallID(const char *id)
{
    return instalar(tabla.identifiers, &tabla.totalID, id);
}

/* Instala un numero en la tabla de NUMBER. */
int InstallNum(const char *numero)
{
    return instalar(tabla.numbers, &tabla.totalNum, numero);
}

/* =====================================================================
 * Muestra las tablas de simbolos por stderr, para no mezclarlas con
 * la salida de tokens (stdout).
 * ===================================================================== */
static void imprimirTablas(void)
{
    int i;

    fprintf(stderr, "\n--- TABLA DE SIMBOLOS: ID ---\n");
    for (i = 0; i < tabla.totalID; i++)
        fprintf(stderr, "posicion %d: %s\n", i + 1, tabla.identifiers[i]);

    fprintf(stderr, "--- TABLA DE SIMBOLOS: NUMBER ---\n");
    for (i = 0; i < tabla.totalNum; i++)
        fprintf(stderr, "posicion %d: %s\n", i + 1, tabla.numbers[i]);
}

/* =====================================================================
 * Programa principal: imprime cada token con el formato del ejemplo.
 * ===================================================================== */
int main(void)
{
    int token;

    while ((token = yylex()) != 0) {
        if (token == TOK_ERROR)
            continue;       /* el error ya se informo en stderr */

        printf("token: %d, yylval: %d, text: %s\n",
               token, yylval, yytext);
    }

    imprimirTablas();

    if (errores > 0)
        fprintf(stderr, "Errores lexicos: %d\n", errores);

    return (errores == 0) ? 0 : 1;
}
