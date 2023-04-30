# Makefile to build x48 without autotools

CC = gcc

GUI_IS_X11 = 1
#GUI_IS_SDL1 = 1

CFLAGS = -g -O2 #-Wall -Wextra -Wno-unused-parameter -Wno-unused-function -Wconversion -Wdouble-promotion -Wno-sign-conversion -fsanitize=undefined -fsanitize-trap
LIBS = -lm -lhistory -lreadline

ifdef GUI_IS_X11
	CFLAGS += -D 'GUI_IS_X11 = 1'
	LIBS += -lX11 -lXext
endif
ifdef GUI_IS_SDL1
	CFLAGS += $(shell pkg-config --cflags SDL_gfx readline sdl12_compat) -D 'GUI_IS_SDL1 = 1'
	LIBS += $(shell pkg-config --libs SDL_gfx readline sdl12_compat)
endif

all: mkcard checkrom dump2rom x48

# Binaries
mkcard: src/mkcard.o
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

dump2rom: src/dump2rom.o
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

checkrom: src/checkrom.o src/romio.o
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

x48: src/main.o src/actions.o src/debugger.o src/device.o src/disasm.o src/emulate.o src/errors.o src/init.o src/lcd.o src/memory.o src/register.o src/resources.o src/romio.o src/rpl.o src/serial.o src/timer.o src/x48_gui.o src/options.o src/resources.o
	$(CC) $(CFLAGS) $(LIBS) $^ -o $@

# Cleaning
clean:
	rm -f src/*.o

clean-all: clean
	rm -f x48 mkcard checkrom dump2rom

# Formatting
pretty-code:
	clang-format -i src/*.c src/*.h

# Installing
PREFIX = /usr
DOCDIR = $(PREFIX)/doc/x48
MANDIR = $(PREFIX)/man/man1
install: all
	install -m 755 -d -- $(DESTDIR)$(PREFIX)/bin
	install -c -m 755 x48 $(DESTDIR)$(PREFIX)/bin/x48

	install -m 755 -d -- $(DESTDIR)$(PREFIX)/share/x48
	install -c -m 755 mkcard $(DESTDIR)$(PREFIX)/share/x48/mkcard
	install -c -m 755 dump2rom $(DESTDIR)$(PREFIX)/share/x48/dump2rom
	install -c -m 755 checkrom $(DESTDIR)$(PREFIX)/share/x48/checkrom
	install -c -m 644 hplogo.png $(DESTDIR)$(PREFIX)/share/x48/hplogo.png
	cp -R ROMs/ $(DESTDIR)$(PREFIX)/share/x48/
	find $(DESTDIR)$(PREFIX)/share/x48/ROMs/ -name "*.bz2" -exec bunzip2 {} \;
	sed "s|PREFIX|$(PREFIX)|g" setup-home.sh > $(DESTDIR)$(PREFIX)/share/x48/setup-x48-home.sh
	chmod 755 $(DESTDIR)$(PREFIX)/share/x48/setup-x48-home.sh

	install -m 755 -d -- $(DESTDIR)$(MANDIR)
	install -c -m 644 x48.man.1 $(DESTDIR)$(MANDIR)/x48.1
	gzip -9  $(DESTDIR)$(MANDIR)/x48.1

	install -m 755 -d -- $(DESTDIR)$(DOCDIR)
	cp -R AUTHORS COPYING ChangeLog INSTALL LICENSE README doc/ romdump/ $(DESTDIR)$(DOCDIR)

	install -m 755 -d -- $(DESTDIR)$(PREFIX)/share/applications
	sed "s|PREFIX|$(PREFIX)|g" x48.desktop > $(DESTDIR)$(PREFIX)/share/applications/x48.desktop

	install 0m 755 -d -- $(DESTDIR)/etc/X11/app-defaults
	install -c -m 644 X48.ad $(DESTDIR)/etc/X11/app-defaults/X48
