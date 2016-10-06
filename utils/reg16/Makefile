TARGET=reg16
MANPAGE=reg16.1.gz

CFLAGS=-Wall -Wextra -Werror -Wpedantic -std=c99

SOURCES=main.c
OBJS=$(SOURCES:.c=.o)
DEPS=$(OBJS:.o=.d)

%.d: %.o

%.o: %.c
	gcc $(CFLAGS) -MMD -c $< -o $@ 

$(TARGET): $(OBJS)
	gcc $(LDFLAGS) $(OBJS) -o $@

all: $(TARGET)

install: $(TARGET) $(MANPAGE) 
	install -m 0755 -d $(DESTDIR)/usr/sbin/
	install -m 0775 $(TARGET) $(DESTDIR)/usr/sbin/
	install -m 0755 -d $(DESTDIR)/usr/share/man/man1/
	install -m 0644 $(MANPAGE) $(DESTDIR)/usr/share/man/man1/

man: $(MANPAGE)

$(MANPAGE): README.md
	ln -sf README.md reg16.1.ronn; \
	  ronn -r reg16.1.ronn; \
	  gzip reg16.1; \
	  rm reg16.1.ronn

dpkg deb: $(TARGET)
	dpkg-buildpackage -B -d

clean:
	rm -f $(TARGET) $(OBJS) $(DEPS) $(MANPAGE)

mrproper:
	dh_clean

.PHONY: all install clean mrproper dpkg deb man


