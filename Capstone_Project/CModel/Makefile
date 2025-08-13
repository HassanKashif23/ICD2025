# Makefile for AXI Stream Packet Parser C model

# Compiler
CC = gcc

# Source files
SRCS = Cmodel.c EthernetHeader.c IPv4.c metadata.c

# Output binary name
OUT_DIR = output
TARGET = $(OUT_DIR)/output.exe

# Compiler flags
CFLAGS = -Wall -Werror

# Default rule
all: $(TARGET)

# Linking rule
$(TARGET): $(SRCS)
	@mkdir -p $(OUT_DIR)
	$(CC) $(CFLAGS) $(SRCS) -o $(TARGET)

# Clean rule
clean:
	rm -f $(TARGET)
