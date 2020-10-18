
build:
	iverilog -Wall -v -o ./test -g2005-sv  ecpri.v tb_ecpri.v

fsm:
	plantuml -v -keepfiles -tsvg ./ecpri_fsm_0.txt 
	plantuml -v -keepfiles -tsvg ./ecpri_fsm_1.txt 

block:
	dot -v -Tsvg ./ecpri_block_0.txt  -o ecpri_block_0.svg
	dot -v -Tsvg ./ecpri_block_1.txt  -o ecpri_block_1.svg
	dot -v -Tsvg ./ecpri_block_2.txt  -o ecpri_block_2.svg

pcap: 
	iverilog -Wall -g2012 -v -s dummy -o ./test_sv test_pcap.sv ecpri.sv read_pcap.sv write_pcap.sv 

run :
	vvp ./test

clean :
	rm  ./test 
