
build:
	iverilog -Wall -o ./test_ecpri -g2005-sv  ecpri_rx.v ecpri_tx.v tb_ecpri.v
	iverilog -Wall -o ./test_ram -g2005-sv  ram.v tb_ram.v

run_ecpri :
	vvp ./test_ecpri

run_ram:
	vvp -v ./test_ram

clean :
	rm  ./test_ecpri
	rm  ./test_ram 
	rm  ./test_ram.vcd
	rm  ./test_ecpri.vcd
