
build:
	rm ./build.log
	iverilog -Wall -o ./test_ram -g2005-sv  ram.v tb_ram.v | tee -a build.log
	iverilog -Wall -o ./test_ram_dual_port -g2005-sv  ram_dual_port.v tb_ram_dual_port.v | tee -a build.log

run_ram:
	vvp -v ./test_ram | tee -a build.log
	vvp -v ./test_ram_dual_port | tee -a build.log

clean :
	rm  ./build.log
	rm  ./test_ram 
	rm  ./test_ram_dual_port
	rm  ./test_ram.vcd
	rm  ./test_ram_dual_port.vcd
