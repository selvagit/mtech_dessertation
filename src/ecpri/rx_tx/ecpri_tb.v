// create test bench

`timescale 1 us / 1 ns

module tb_ecpri();

parameter DATA_WIDTH = 8 ;
parameter ADDR_WIDTH = 16 ;

// variable for linking the modules
reg send_write_resp, send_read_resp; 
reg [DATA_WIDTH-1:0] resp_payload_len; 

reg [ADDR_WIDTH-1:0] addr_0;
wire [DATA_WIDTH-1:0] data_0; 
reg we_0, oe_0; //info_to_tx, 

reg [ADDR_WIDTH-1:0] addr_1;
wire [DATA_WIDTH-1:0] data_1; 
reg we_1, oe_1; 

reg [ADDR_WIDTH-1:0] addr_2; 
wire [DATA_WIDTH-1:0] data_2; 
reg we_2, oe_2; //data_to_mem,   

reg clk, clk_0, clk_1; 
reg cs_0, cs_1;
reg [DATA_WIDTH-1:0] inp_data_fifo; 
reg recv_pkt, reset;

// variables for use in the test bench
// variable related to file operation
reg [DATA_WIDTH-1:0] freg;
integer fd, eof, fdw;
integer total_bytes;
integer errorno;
reg [225*8:1] err_str;
reg [DATA_WIDTH-1:0] temp_mem [1500];
reg [DATA_WIDTH-1:0] tb_data;

integer i;

/*
// ecpri_rx module instanstion
ecpri_rx dut_ecpri_rx(
    .send_write_resp(send_write_resp), .send_read_resp(send_read_resp), .resp_payload_len(resp_payload_len), 
    .addr_0(addr_0), .data_0(data_0), .we_0(we_0), .oe_0(oe_0), //info_to_tx, 
    .addr_1(addr_1), .data_1(data_1), .we_1(we_1), .oe_1(oe_1), 
    .addr_2(addr_2), .data_2(data_2), .we_2(we_2), .oe_2(oe_2), //data_to_mem,   
    .clk(clk), .inp_data_fifo(inp_data_fifo), .recv_pkt(recv_pkt), .reset(reset)
);
*/

//#instantion of the ram modules
//ram where the incoming packets are stored
ram_dp_sr_sw  ram_recv_eth_packet (
	.clk(clk)       , // Clock Input
	.address_0(addr_0)  , // address_0 Input
	.data_0(data_0)    , // data_0 bi-directional
	.cs_0(cs_0)      , // Chip Select
	.we_0(we_0)      , // Write Enable/Read Enable
	.oe_0(oe_0)      , // Output Enable
	.address_1(addr_1)    , // address_1 Input
	.data_1(data_1)    , // data_1 bi-directional
	.cs_1(cs_1)      , // Chip Select
	.we_1(we_1)      , // Write Enable/Read Enable
	.oe_1(oe_1)        // Output Enable
); 

/*
//ram where the cpri payload is written/read from, 
//this ram is also accessible from the cpu
ram_dp_sr_sw  ram_cpri_payload (
    .clk(clk)       , // Clock Input
	.address_0(addr_0)  , // address_0 Input
	.data_0(data_0)    , // data_0 bi-directional
	.cs_0(cs_0)      , // Chip Select
	.we_0(we_0)      , // Write Enable/Read Enable
	.oe_0(oe_0)      , // Output Enable
	.address_1(addr_1)    , // address_1 Input
	.data_1(data_1)    , // data_1 bi-directional
	.cs_1(cs_1)      , // Chip Select
	.we_1(we_1)      , // Write Enable/Read Enable
	.oe_1(oe_1)        // Output Enable
);    

//this ram is used for storing the resp packet
ram_dp_sr_sw  ram_cpri_packet (
    .clk(clk)       , // Clock Input
	.address_0(addr_0)  , // address_0 Input
	.data_0(data_0)    , // data_0 bi-directional
	.cs_0(cs_0)      , // Chip Select
	.we_0(we_0)      , // Write Enable/Read Enable
	.oe_0(oe_0)      , // Output Enable
	.address_1(addr_1)    , // address_1 Input
	.data_1(data_1)    , // data_1 bi-directional
	.cs_1(cs_1)      , // Chip Select
	.we_1(we_1)      , // Write Enable/Read Enable
	.oe_1(oe_1)        // Output Enable
);  

//this ram is used for storing the recevied eth packet hdr
ram_dp_sr_sw  ram_eth_packet_hdr (
    .clk(clk)       , // Clock Input
	.address_0(addr_0)  , // address_0 Input
	.data_0(data_0)    , // data_0 bi-directional
	.cs_0(cs_0)      , // Chip Select
	.we_0(we_0)      , // Write Enable/Read Enable
	.oe_0(oe_0)      , // Output Enable
	.address_1(addr_1)    , // address_1 Input
	.data_1(data_1)    , // data_1 bi-directional
	.cs_1(cs_1)      , // Chip Select
	.we_1(we_1)      , // Write Enable/Read Enable
	.oe_1(oe_1)        // Output Enable
); 
*/

// reset the vriable & provide clock 
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

assign data_0 = !oe_0 ? tb_data : 'hz;

// provide input to the module 
initial begin 
    #10;
    reset <= 0;
    #20;
    $display ("0");
    fd = $fopen("../gen_pcap/gen_ecpri.pcap","rb"); 
    if ( fd ) begin 
        $display ("pcap file was opened");
        fdw = $fopen("cp_ecpri.pcap","wb"); 
    end else begin
        errorno = $ferror(fd, err_str);
        $display ("pcap file could not be opened %s", err_str);
        $finish; // end simulation
    end 

    eof = $fread(temp_mem,fd);
    $fclose (fd);
    $display ("File closed");
    #50 
    $display ("1");
    //repeat (1) @(posedge clk)  addr_0 = 0; we_0 = 0; cs_0 = 0; oe_0 = 0; tb_data = 0;
    //repeat (1) @(posedge clk)  addr_1 <= i; we_1 <= 1; cs_1 <= 1; oe_1 <= 0; tb_data <= 0;

    #50;
    $display ("2");
    for ( i = 0; i < 100; i = i + 1) begin 
        repeat (1) @(posedge clk) addr_0 = i; we_0 = 1; cs_0 = 1; oe_0 = 0; tb_data = temp_mem[i];
        //$display ("ram_dp_inp_data %d %d ", tb_data, data_0);
    end
    #50;
    $display ("3");
    $finish;
end

// dump the output 
initial begin
    $dumpfile("ecpri.vcd");
    $dumpvars(0,tb_ecpri);
    $dumpvars(0,ram_recv_eth_packet);
end

endmodule
