
build:
	iverilog -Wall -o ./ecpri_tb.bin -g2005-sv ram_dual_port.v ecpri_rx.v ecpri_tx.v ecpri_tb.v

run:
	vvp ./ecpri_tb.bin

clean :
	rm  ./ecpri_tb.bin
	rm  ./ecpri.vcd
