// create test bench
module tb_ecpri();

parameter DATA_WIDTH = 8 ;
parameter ADDR_WIDTH = 16 ;

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

integer j;

// ecpri_rx module instanstion
ecpri_rx dut_ecpri_rx(
    send_write_resp, send_read_resp, resp_payload_len, 
    addr_0, data_0, we_0, oe_0, //info_to_tx, 
    addr_1, data_1, we_1, oe_1, 
    addr_2, data_2, we_2, oe_2, //data_to_mem,   
    clk, inp_data_fifo, recv_pkt, reset
);

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

// reset the vriable & provide clock 
initial begin 
    forever #10 clk <=~clk;
end

// provide input to the module 
initial begin 
    #10;
    reset <= 0;
    #20
    $finish;
end

// dump the output 
initial begin
    $dumpfile("ecpri.vcd");
    $dumpvars(0,dut_ecpri_rx);
end

endmodule
