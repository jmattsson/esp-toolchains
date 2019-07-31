# Based off the nodemcu-prebuilt-toolchains repo, but intended for packaging
# up the toolchains rather than checking them into the repo itself.
default: esp8266 esp32

TOPDIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
DATE:=$(shell date +%Y%m%d)
RELVER?=0
OS?=linux
ARCH=$(shell uname -m)
VER:=$(OS)-$(ARCH)-$(DATE).$(RELVER)

Q?=@

.PHONY: esp32 esp8266
esp32: build/toolchain-esp32-$(VER).tar.xz
esp8266: build/toolchain-esp8266-$(VER).tar.xz

build/lx106/Makefile:
	$Qcd build && git clone --recursive https://github.com/pfalcon/esp-open-sdk.git lx106

build/lx106/patched: build/lx106/Makefile
	$Qcd "$(dir $@)" && patch -p0 < ../../esp8266-configure.patch
	@touch $@

esp8266-$(VER)/bin/xtensa-lx106-elf-gcc: build/lx106/patched
	$Qecho CT_STATIC_TOOLCHAIN=y >> $(dir $<)/crosstool-config-overrides
	$Qcd "$(dir $<)" && $(MAKE) STANDALONE=n TOOLCHAIN="$(TOPDIR)/esp8266-$(VER)" toolchain libhal

build/toolchain-esp8266-$(VER).tar.xz: esp8266-$(VER)/bin/xtensa-lx106-elf-gcc
	@echo 'Packaging toolchain ($@)...'
	$Qtar cJf $@ esp8266-$(VER)/
	$Qtouch $@
	@echo [32m[DONE] $@[0m


build/esp32/bootstrap:
	$Qcd build && git clone -b esp32-2019r1_ctng-1.23.x https://github.com/espressif/crosstool-NG.git esp32
	@touch $@

build/esp32/patched: build/esp32/bootstrap
	$Qcd "$(dir $@)" && patch -p0 < ../../esp32-configure.patch
	@touch $@

build/esp32/Makefile: build/esp32/patched
	$Qcd "$(dir $@)" && ./bootstrap && ./configure --prefix="`pwd`"

build/esp32/ct-ng: build/esp32/Makefile
	$Qcd "$(dir $@)" && $(MAKE) MAKELEVEL=0 && $(MAKE) MAKELEVEL=0 install

build/esp32/.config: build/esp32/ct-ng
	$Qcd "$(dir $@)" && ./ct-ng xtensa-esp32-elf
	$Qsed -i 's,^CT_PREFIX_DIR=.*$$,CT_PREFIX_DIR="$${CT_TOP_DIR}/../../esp32-$(VER)",' $@
	$Qecho CT_STATIC_TOOLCHAIN=y >> $@

esp32-$(VER)/bin/xtensa-esp32-elf-gcc: build/esp32/.config
	$Qcd "$(dir $<)" && ./ct-ng build
	@echo Fixing up directory permissions...
	$Qchmod -R u+w "esp32-$(VER)"

build/toolchain-esp32-$(VER).tar.xz: esp32-$(VER)/bin/xtensa-esp32-elf-gcc
	@echo 'Packaging toolchain ($@)...'
	$Qtar cJf $@ esp32-$(VER)/
	$Qtouch $@
	@echo [32m[DONE] $@[0m


.PHONY:clean
clean:
	-rm -rf build/esp32 build/lx106 build/toolchain-*.tar.xz esp8266-* esp32-*

.SUFFIXES:
%: %,v
%: RCS/%,v
%: RCS/%
%: s.%
%: SCCS/s.%

