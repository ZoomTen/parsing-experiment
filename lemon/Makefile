.PHONY: all

all: lemon

lemon: lemon.c
	$(CC) $(CFLAGS) -O3 -flto -o $@ $^

clean:
	rm -fv lemon
