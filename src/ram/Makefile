
build:
	iverilog -Wall -o ./test_ram -g2005-sv  ram.v tb_ram.v

run_ram:
	vvp -v ./test_ram

clean :
	rm  ./test_ram 
	rm  ./test_ram.vcd
