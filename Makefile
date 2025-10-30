NAME="volume-pulse"
all:
	@echo "crystal build (NEW)"
	@echo "c build"
crystal:
	@shards build $(NAME) -Dpreview_mt -Dexecution_context --release
c:
	mkdir -p "bin/c"
	@gcc -O2 -s -DNDEBUG -w src/main.c -o bin/c/$(NAME)  \
		$(shell pkg-config --cflags gtk+-2.0 x11 libnotify) \
        $(shell pkg-config --libs gtk+-2.0 x11 libnotify)

.PHONY: all crystal c
