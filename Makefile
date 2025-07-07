# Makefile for PubNub C-Core Subscribe Bug Reproduction
# This Makefile is based on the PubNub C-Core POSIX examples

# Configuration
CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -g -O0
LDFLAGS = -lpthread

# PubNub C-Core paths - adjust these to match your installation
PUBNUB_ROOT = ./pubnub-c-core
PUBNUB_CORE = $(PUBNUB_ROOT)/core
PUBNUB_LIB = $(PUBNUB_ROOT)/lib
PUBNUB_POSIX = $(PUBNUB_ROOT)/posix

# Include paths
INCLUDES = -I$(PUBNUB_CORE) -I$(PUBNUB_LIB) -I$(PUBNUB_POSIX)

# Source files - core PubNub files needed for sync operation
PUBNUB_SOURCES = \
	$(PUBNUB_CORE)/pubnub_pubsubapi.c \
	$(PUBNUB_CORE)/pubnub_coreapi.c \
	$(PUBNUB_CORE)/pubnub_coreapi_ex.c \
	$(PUBNUB_CORE)/pubnub_ccore.c \
	$(PUBNUB_CORE)/pubnub_netcore.c \
	$(PUBNUB_CORE)/pubnub_alloc_std.c \
	$(PUBNUB_CORE)/pubnub_assert_std.c \
	$(PUBNUB_CORE)/pubnub_generate_uuid.c \
	$(PUBNUB_CORE)/pubnub_blocking_io.c \
	$(PUBNUB_CORE)/pubnub_timers.c \
	$(PUBNUB_CORE)/pubnub_json_parse.c \
	$(PUBNUB_CORE)/pubnub_helper.c \
	$(PUBNUB_CORE)/pubnub_free_with_timeout.c \
	$(PUBNUB_CORE)/pubnub_log.c \
	$(PUBNUB_POSIX)/pubnub_version_posix.c \
	$(PUBNUB_POSIX)/pubnub_generate_uuid_posix.c \
	$(PUBNUB_POSIX)/pbpal_posix_blocking_io.c \
	$(PUBNUB_POSIX)/pbpal_posix_adns.c \
	$(PUBNUB_POSIX)/pbpal_adns_sockets.c \
	$(PUBNUB_POSIX)/pbpal_posix_resolv_and_connect.c \
	$(PUBNUB_POSIX)/pbpal_posix_resolv_and_connect_sockets.c \
	$(PUBNUB_POSIX)/pbpal_posix_resolv_and_connect_common.c \
	$(PUBNUB_POSIX)/pbtimespec_elapsed_ms.c \
	$(PUBNUB_POSIX)/pubnub_dns_codec.c \
	$(PUBNUB_POSIX)/pbpal_ntf_callback_posix.c \
	$(PUBNUB_POSIX)/pbpal_ntf_callback_poller_poll.c \
	$(PUBNUB_POSIX)/pubnub_ntf_sync.c

# Object files
PUBNUB_OBJECTS = $(PUBNUB_SOURCES:.c=.o)

# Target executable
TARGET = pubnub_subscribe_bug_reproduction

# Default target
all: $(TARGET)

# Main target
$(TARGET): pubnub_subscribe_bug_reproduction.o $(PUBNUB_OBJECTS)
	$(CC) -o $@ $^ $(LDFLAGS)

# Main source compilation
pubnub_subscribe_bug_reproduction.o: pubnub_subscribe_bug_reproduction.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# PubNub source compilation
%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Clean target
clean:
	rm -f $(TARGET) *.o $(PUBNUB_OBJECTS)

# Help target
help:
	@echo "PubNub C-Core Subscribe Bug Reproduction Makefile"
	@echo ""
	@echo "Prerequisites:"
	@echo "  1. Download PubNub C-Core from: https://github.com/pubnub/c-core"
	@echo "  2. Extract to './pubnub-c-core' or adjust PUBNUB_ROOT in Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build the reproduction program (default)"
	@echo "  clean     - Remove built files"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Usage:"
	@echo "  make                    # Build the program"
	@echo "  ./$(TARGET)            # Run the reproduction test"
	@echo "  make clean              # Clean up build files"

.PHONY: all clean help