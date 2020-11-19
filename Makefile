# 
# for use with github
#
# Set variables to pass
#

target = uforth.c

#
# make what to make
#
auto-up: 

	avr-gcc -mmcu=atmega8 -O -S $(target) 2>&1 | tee err
up:

down:

clean:

build:

sync: 

migrate:

wait:

logs:

pull:

smoketest:

unittest:

test: 

reset: 

hardreset: 

develop: 

