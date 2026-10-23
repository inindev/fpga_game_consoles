#
# The xPack GNU RISC-V Embedded GCC
# https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack
#
TARGET_ELF = firmware.elf
TARGET_BIN = firmware.bin
RISCV = /opt/xpack-riscv-none-elf-gcc-13.2.0-2/bin/riscv-none-elf
CC = $(RISCV)-gcc
OBJCOPY = $(RISCV)-objcopy
OBJDUMP = $(RISCV)-objdump
CFLAGS  = -Wall -O2 -g -mabi=ilp32 -march=rv32i -ffreestanding
LFLAGS = -mabi=ilp32 -march=rv32i -Wl,--build-id=none,-Bstatic,-T,baremetal.ld -nostdlib
LIBS = -lgcc

# Version shown in the menu: git commit (+ if there are uncommitted changes) and build date.
# version.h is rewritten only when this text changes, so firmware.c recompiles once per
# new commit or day rather than on every make.
VERSION := $(shell git describe --always --dirty=+ 2>/dev/null || echo unknown) $(shell date +%Y-%m-%d)

SRCS := start.S firmware.c picorv32.c spi_sd.c spiflash.c \
	fatfs/diskio.c fatfs/ff.c fatfs/ffunicode.c
OBJS := $(SRCS:.c=.o)
OBJS := $(OBJS:.S=.o)
HDRS := $(filter-out version.h,$(wildcard *.h))

ifeq ($(VERBOSE),1)
  Q =
else
  Q = @
endif

default: $(TARGET_BIN)
all: default

%.o: %.c $(HDRS)
ifneq ($(VERBOSE),1)
	@echo CC $@
endif
	$(Q)$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S $(HDRS)
ifneq ($(VERBOSE),1)
	@echo CC $@
endif
	$(Q)$(CC) $(CFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET_BIN) $(TARGET_ELF) $(OBJS)

$(TARGET_ELF): $(OBJS)
ifneq ($(VERBOSE),1)
	@echo CC $@
endif
	$(Q)$(CC) $(LFLAGS) $(OBJS) $(LIBS) -o $@

$(TARGET_BIN): $(TARGET_ELF)
ifneq ($(VERBOSE),1)
	@echo OBJCOPY $@
endif
	$(Q)$(OBJCOPY) $(TARGET_ELF) $(TARGET_BIN) -O binary

version.h: FORCE
	@echo '#define FW_VERSION "$(VERSION)"' > $@.tmp
	@cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

firmware.o: version.h

clean:
	$(Q)rm -f $(OBJS) $(TARGET_ELF) $(TARGET_BIN) version.h

.PHONY: default all clean FORCE
