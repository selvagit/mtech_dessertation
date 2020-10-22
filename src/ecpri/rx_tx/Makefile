
build:
	iverilog -Wall -o ./test_ecpri -g2005-sv  ecpri_rx.v ecpri_tx.v tb_ecpri.v

run_ecpri :
	vvp ./test_ecpri

clean :
	rm  ./test_ecpri
	rm  ./test_ecpri.vcd
