
pcap: 
	#iverilog -Wall -g2012 -o ./test_pcap test_pcap.sv read_pcap.sv write_pcap.sv 
	iverilog -Wall -g2012 -o ./test_pcap test_pcap.sv 

run :
	vvp ./test_pcap

clean :
	rm  ./test_pcap
