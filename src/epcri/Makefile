
build:
	iverilog -Wall -v -o ./test -g2005-sv  ecpri.v tb_ecpri.v

pcap: 
	iverilog -Wall -v -o ./test_sv -g2012 read_pcap.sv write_pcap.sv test_pcap.sv 

run :
	vvp ./test

clean :
	rm  ./test
