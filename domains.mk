ifeq ($(strip $(MICROKIT_SDK)),)
$(error MICROKIT_SDK must be specified)
endif

BUILD_DIR ?= build
# By default we make a debug build so that the client debug prints can be seen.
MICROKIT_CONFIG ?= debug

QEMU := qemu-system-aarch64

CC := clang
LD := ld.lld
AR := llvm-ar
RANLIB := llvm-ranlib

MICROKIT_TOOL ?= $(MICROKIT_SDK)/bin/microkit

IMAGES := inc.elf
CFLAGS := -mcpu=$(CPU) \
	-mstrict-align \
	-nostdlib \
	-ffreestanding \
	-g3 \
	-O3 \
	-Wall -Wno-unused-function -Werror -Wno-unused-command-line-argument \
	-target aarch64-none-elf \
	-I$(BOARD_DIR)/include
LDFLAGS := -L$(BOARD_DIR)/lib
LIBS := --start-group -lmicrokit -Tmicrokit.ld --end-group

IMAGE_FILE := loader.img
REPORT_FILE := report.txt
SYSTEM_FILE := ${TOP}/domains.system
CLIENT_OBJS := inc.o

all: $(IMAGE_FILE)
CHECK_FLAGS_BOARD_MD5:=.board_cflags-$(shell echo -- ${CFLAGS} ${BOARD} ${MICROKIT_CONFIG} | shasum | sed 's/ *-//')

${CHECK_FLAGS_BOARD_MD5}:
	-rm -f .board_cflags-*
	touch $@

inc.o: ${TOP}/inc.c
	$(CC) -c $(CFLAGS) $< -o inc.o
inc.elf: inc.o
	$(LD) $(LDFLAGS) $< $(LIBS) -o $@

$(IMAGE_FILE) $(REPORT_FILE): $(IMAGES) $(SYSTEM_FILE)
	$(MICROKIT_TOOL) $(SYSTEM_FILE) --search-path $(BUILD_DIR) --board $(MICROKIT_BOARD) --config $(MICROKIT_CONFIG) -o $(IMAGE_FILE) -r $(REPORT_FILE)

qemu: $(IMAGE_FILE)
	$(QEMU) -machine virt,virtualization=on \
			-cpu cortex-a53 \
			-serial mon:stdio \
			-device loader,file=$(IMAGE_FILE),addr=0x70000000,cpu-num=0 \
			-m size=2G \
			-nographic

clean::
	rm -f inc.o
clobber:: clean
	rm -f inc.elf ${IMAGE_FILE} ${REPORT_FILE}
