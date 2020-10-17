
build:
	iverilog -Wall -v -o ./test -g2005-sv  ecpri.v tb_ecpri.v

pcap: 
	iverilog -Wall -g2012 -v -s dummy -o ./test_sv test_pcap.sv ecpri.sv read_pcap.sv write_pcap.sv 

run :
	vvp ./test

clean :
	rm  ./test
