//`timescale 1 ns/1 ps

`include "./pcap_src/write_pcap.sv"
`include "./pcap_src/read_pcap.sv"
`include "./pcap_src/ecpri.sv"

`define CLK_PERIOD 10 // 10ns

module test;
    //generate clk
    reg clk=0;
    always #(`CLK_PERIOD/2) clk <= ~clk;

    reg [7:0] buf_packet_out[64];
    reg       buf_packet_en_out;
    reg       end_read;
    integer   wfd;
    integer   rfd;

    dummy dut (.out(buf_packet_out), .inp(buf_packet_out), .clk(clk) ) ;

    initial begin
    wfd = $fopen("./ecpri.pcap","wb");
    rfd = $fopen("packet_out.pcap","r");
    end

    always@(posedge clk) 
    begin
        read_pcap_task (rfd,clk, buf_packet_en_out, buf_packet_out, end_read);
        write_pcap_task (wfd, clk, buf_packet_en_out, buf_packet_out);
    end

    always@(posedge clk) 
    begin
        if (end_read==1) 
        begin
            $finish();
        end
    end

endmodule
