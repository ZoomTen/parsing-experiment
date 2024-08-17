CC=clang
CFLAGS=-std=c99 -Weverything -Wno-unsafe-buffer-usage -Wno-gnu-case-range -O3
ALL=convert ../lemon/lemon

all: $(ALL)

%: %.c
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $^

../lemon/lemon: CFLAGS=-std=c99 -O3

convert: convert.c lexer.c grammar.o
convert.c: datatypes.h
lexer.c: datatypes.h grammar.h

grammar.y: datatypes.h
grammar.o: CFLAGS=-c -std=c99 -O3
grammar.c grammar.h grammar.out: grammar.y ../lemon/lemon
	cd ../lemon && ./lemon ../skxs_text/$<

clean:
	rm -fv $(ALL)
	rm -fv grammar.c grammar.h grammar.out grammar.o
