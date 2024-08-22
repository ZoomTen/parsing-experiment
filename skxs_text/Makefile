CC=gcc
CFLAGS=-std=c99 -Wall -Wno-unsafe-buffer-usage -Wno-gnu-case-range -O3
ALL=convert ../lemon/lemon

all: $(ALL)

%: %.c
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $^

../lemon/lemon: CFLAGS=-std=c99 -O3

convert: convert.c lexer.c txt_grammar.o
convert.c: datatypes.h
lexer.c: datatypes.h txt_grammar.h

txt_grammar.y: datatypes.h
txt_grammar.o: CFLAGS=-c -std=c99 -O3
txt_grammar.c txt_grammar.h txt_grammar.out: txt_grammar.y ../lemon/lemon
	cd ../lemon && ./lemon ../skxs_text/$<

clean:
	rm -fv $(ALL)
	rm -fv txt_grammar.c txt_grammar.h txt_grammar.out txt_grammar.o
