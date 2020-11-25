# My third makefile

# Name of the project
PROJ_NAME=u2forth

# .c files
C_SOURCE=$(wildcard *.c)

# .h files
H_SOURCE=$(wildcard *.h)

# Assembler files
ASM=$(subst .c,.s, *.c)

# Object files
OBJ=$(subst .c,.o, *.c)

# Compiler and linker
CC=avr-gcc

# Flags for compiler
CC_FLAGS_COMMON= \
	-c         \
    -W         \
    -Wall      \
    -ansi      \
    -pedantic 

CC_FLAGS_SPECS= \
	-fpic \
	-mmcu=atmega8 \
    -mcall-prologues \
	-fverbose-asm 

# Flags for compiler
CC_FLAGS= $(CC_FLAGS_COMMON) $(CC_FLAGS_SPECS)
        
# Command used at clean target
RM = rm -rf

#
# Compilation and linking
#
all: $(PROJ_NAME)

$(PROJ_NAME): $(OBJ)
	@ echo 'Building binary using GCC linker: $@'
	$(CC) $(CC_FLAGS) $^ -o $@
	@ echo 'Finished building binary: $@'
	@ echo ' '

.%.o: ./%.s 
	@ echo 'Building object target using GCC compiler: $<'
	$(CC) $< $(CC_FLAGS) -o $@
	@ echo ' '

.%.s: ./%.c ./%.h
	@ echo 'Building assembler target using GCC compiler: $<'
	$(CC) $< $(CC_FLAGS) -S $@
	@ echo ' '

#objFolder:
#	@ mkdir -p objects
#	@ rmdir objects
#

clean:
	@ echo 'Clearing all objects '
	@ $(RM) ./*.o ./*.s *~ $(PROJ_NAME)

.PHONY: all clean

