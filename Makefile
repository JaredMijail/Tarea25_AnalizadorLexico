FLEX   = flex
CC     = gcc
CFLAGS = -Wall -Wextra -O2
GEN    = build/lex.yy.c
BIN    = build/analizador

.PHONY: all test clean

all: $(BIN)

$(GEN): lexer.l
	@mkdir -p build
	$(FLEX) -o $@ $<

$(BIN): $(GEN)
	$(CC) $(CFLAGS) -o $@ $<

test: $(BIN)
	@./pruebas/ejecutar.sh

clean:
	rm -f $(GEN) $(BIN) resultados/*.out resultados/*.err
