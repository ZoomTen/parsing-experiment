.SUFFIXES:
.PHONY: all lemon clean
.SECONDARY:

OBJECTS := \
	src/driver.o \
	\
	src/lexer/script.o \
	src/lexer/charmap.l.o \
	\
	src/parser/script.o \
	src/parser/charmap.o \
	\
	src/process/charmap.o \
	src/process/script.o

CC := gcc
LEX := flex
CFLAGS_ := $(CFLAGS) -std=c99 -Wall -Wno-unsafe-buffer-usage -Wno-gnu-case-range -O3
LEXOPTS := -L
LEMOPTS := -l

all: tx_parse

lemon:
	$(MAKE) -C ../lemon

tx_parse: $(OBJECTS)
	$(CC) $(CFLAGS_) -o $@ $^

%.o: %.c
	$(CC) -c $(CFLAGS_) -o $@ $<

%.l.c: %.l
	$(LEX) $(LEXOPTS) -o $@ $<

src/parser/%.c src/parser/%.h src/parser/%.out: src/parser/%.y lemon
	../lemon/lemon $(LEMOPTS) $<

src/lexer/script.c: src/parser/script.h

src/lexer/charmap.l.c: src/parser/charmap.h

clean:
	rm -fv \
		$(OBJECTS) \
		src/lexer/*.l.c \
		src/parser/*.c \
		src/parser/*.h \
		src/parser/*.out
