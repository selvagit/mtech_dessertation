// create test bench

`timescale 1 us / 1 ns

module tb_ecpri();

parameter DATA_WIDTH = 8 ;
parameter ADDR_WIDTH = 16 ;

// edge to the eth ram 

reg [ADDR_WIDTH-1:0] addr_to_eth_ram;
wire [DATA_WIDTH-1:0] data_to_eth_ram; 
reg we_to_eth_ram, oe_to_eth_ram; 

// edge to and from the ecpri_rx
reg [ADDR_WIDTH-1:0] addr_ecpri_rx_2_eth_ram;
wire [DATA_WIDTH-1:0] data_ecpri_rx_2_eth_ram; 
reg we_ecpri_rx_2_eth_ram, oe_ecpri_rx_2_eth_ram; 

reg [ADDR_WIDTH-1:0] addr_ecpri_rx_2_ram_eth_packet_hdr;
wire [DATA_WIDTH-1:0] data_ecpri_rx_2_ram_eth_packet_hdr;
reg we_ecpri_rx_2_ram_eth_packet_hdr, oe_ecpri_rx_2_ram_eth_packet_hdr; 

reg [ADDR_WIDTH-1:0] addr_ecpri_rx_2_ram_cpri_packet;
wire [DATA_WIDTH-1:0] data_ecpri_rx_2_ram_cpri_packet;
reg we_ecpri_rx_2_ram_cpri_packet, oe_ecpri_rx_2_ram_cpri_packet; 

reg [ADDR_WIDTH-1:0] addr_ecpri_rx_2_ram_cpri_payload;
wire [DATA_WIDTH-1:0] data_ecpri_rx_2_ram_cpri_payload;
reg we_ecpri_rx_2_ram_cpri_payload, oe_ecpri_rx_2_ram_cpri_payload; 

reg send_write_resp, send_read_resp; 
reg [DATA_WIDTH-1:0] resp_payload_len; 

// edge to and from the ecpri_tx
reg [ADDR_WIDTH-1:0] addr_ecpri_tx_2_ram_cpri_payload;
wire [DATA_WIDTH-1:0] data_ecpri_tx_2_ram_cpri_payload;
reg we_ecpri_tx_2_ram_cpri_payload, oe_ecpri_tx_2_ram_cpri_payload; 


// edge to and from the ip

// 
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

//#instantion of the ram modules
//ram where the incoming packets are stored
ram_dp_sr_sw  ram_recv_eth_packet (
	.clk(clk)       , // Clock Input
	.address_0(addr_to_eth_ram)  , // address_0 Input
	.data_0(data_to_eth_ram)    , // data_0 bi-directional
	.cs_0(cs_0)      , // Chip Select
	.we_0(we_to_eth_ram)      , // Write Enable/Read Enable
	.oe_0(oe_to_eth_ram)      , // Output Enable
	.address_1(addr_ecpri_rx_2_eth_ram)    , // address_1 Input
	.data_1(data_ecpri_rx_2_eth_ram)    , // data_1 bi-directional
	.cs_1(cs_1)      , // Chip Select
	.we_1(we_ecpri_rx_2_eth_ram)      , // Write Enable/Read Enable
	.oe_1(oe_ecpri_rx_2_eth_ram)        // Output Enable
); 

// ecpri_rx module instanstion
ecpri_rx dut_ecpri_rx(
    .send_write_resp(send_write_resp), .send_read_resp(send_read_resp), .resp_payload_len(resp_payload_len), 
    .addr_0(addr_ecpri_rx_2_ram_eth_packet_hdr), .data_0(data_ecpri_rx_2_ram_eth_packet_hdr), .we_0(we_ecpri_rx_2_ram_eth_packet_hdr), .oe_0(oe_ecpri_rx_2_ram_eth_packet_hdr), //info_to_tx, 
    .addr_1(addr_ecpri_rx_2_eth_ram), .data_1(data_ecpri_rx_2_eth_ram), .we_1(we_ecpri_rx_2_eth_ram), .oe_1(oe_ecpri_rx_2_eth_ram), 
    .addr_2(addr_ecpri_rx_2_ram_cpri_payload), .data_2(data_ecpri_rx_2_ram_cpri_payload), .we_2(we_ecpri_rx_2_ram_cpri_payload), .oe_2(oe_ecpri_rx_2_ram_cpri_payload), //data_to_mem,   
    .clk(clk), .inp_data_fifo(inp_data_fifo), .recv_pkt(recv_pkt), .reset(reset)
);

//ram where the cpri payload is written/read from, 
//this ram is also accessible from the cpu
ram_dp_sr_sw  ram_cpri_payload (
    .clk(clk)       , // Clock Input
	.address_0(addr_ecpri_rx_2_ram_cpri_payload)  , // address_0 Input
	.data_0(data_ecpri_rx_2_ram_cpri_payload)    , // data_0 bi-directional
	.cs_0(cs_0)      , // Chip Select
	.we_0(we_ecpri_rx_2_ram_cpri_payload)      , // Write Enable/Read Enable
	.oe_0(oe_ecpri_rx_2_ram_cpri_payload)      , // Output Enable
	.address_1(addr_ecpri_tx_2_ram_cpri_payload)    , // address_1 Input
	.data_1(data_ecpri_tx_2_ram_cpri_payload)    , // data_1 bi-directional
	.cs_1(cs_1)      , // Chip Select
	.we_1(we_ecpri_tx_2_ram_cpri_payload)      , // Write Enable/Read Enable
	.oe_1(oe_ecpri_tx_2_ram_cpri_payload)        // Output Enable
);    

/*
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

typedef struct packed       {
    bit [31:00] magic         ; //191:160 
    bit [15:00] version_major ;
    bit [15:00] version_minor ; //159:128
    bit [31:00] thiszone      ; //127:96
    bit [31:00] sigfigs       ; //95:64
    bit [31:00] snaplen       ; //63:32
    bit [31:00] linktype      ; //31:0
}pcap_file_hdr;

typedef struct packed      {
    bit [31:00] tv_sec  ;  //127:96
    bit [31:00] tv_usec ;  //95:64
    bit [31:00] caplen  ;  //63:32 
    bit [31:00] len     ;  //31:0
}pcap_pkt_hdr;

integer pcap_file_hdr_len;
integer pcap_pkt_hdr_len;
integer pcap_payload_offset;
integer pcap_payload_len;
integer pcap_payload_end_addr;

pcap_file_hdr pcap_file_hdr_mem;
pcap_pkt_hdr  pcap_pkt_hdr_mem;

reg [$bits(pcap_file_hdr)-1:0] pcap_file_hdr_flat; 
reg [$bits(pcap_pkt_hdr)-1:0] pcap_pkt_hdr_flat; 

integer return_value ;

// reset the vriable & provide clock 
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

assign data_to_eth_ram = !oe_to_eth_ram ? tb_data : 'hz;

// provide input to the module 
initial begin 
    #10;
    reset = 0;
    addr_to_eth_ram = 0;
    we_to_eth_ram  = 0; 

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
    
    #50;
    $display ("2");
    pcap_payload_len = 0;
    pcap_file_hdr_len = $bits(pcap_file_hdr);
    pcap_pkt_hdr_len = $bits(pcap_pkt_hdr);
    $display( "Size of pcap global header = %d  %d \n", pcap_file_hdr_len,  pcap_file_hdr_len/8);
    $display( "Size of per packet header = %d %d\n", pcap_pkt_hdr_len, pcap_pkt_hdr_len/8);

    pcap_payload_offset = pcap_file_hdr_len/8 + pcap_pkt_hdr_len/8;
    $display( "payload offet = %d \n", pcap_payload_offset);

    fd = $fopen("../gen_pcap/gen_ecpri.pcap","rb"); 
    return_value = $fread(pcap_file_hdr_flat,fd);
    $display ("file hdr bits len =%d", return_value );
    $display ("%h", pcap_file_hdr_flat );
    //assign pcap_file_hdr_mem.linktype = pcap_file_hdr_flat[31:00];
    //assign pcap_file_hdr_mem.snaplen = pcap_file_hdr_flat[63:32];

    return_value = $fread(pcap_pkt_hdr_flat,fd);
    $display ("pkt hdr bits len =%d", return_value );
    $display ("%h", pcap_pkt_hdr_flat );
    //assign pcap_pkt_hdr_mem = pcap_pkt_hdr_flat;

    $fclose(fd);

    $display ("magic =%h", pcap_file_hdr_flat[191:160]);
    $display ("verson_major =%h", pcap_file_hdr_mem.version_major);
    $display ("verson_mnor =%h", pcap_file_hdr_mem.version_minor);
    $display ("thiszone =%h", pcap_file_hdr_mem.thiszone);
    $display ("sigfigs =%h", pcap_file_hdr_mem.sigfigs);
    $display ("snaplen =%h", pcap_file_hdr_flat[63:32]);
    $display ("linktype =%h", pcap_file_hdr_flat[31:00]);
    
    $display ("tv_sec =%d", pcap_pkt_hdr_mem.tv_sec);
    $display ("tv_usec =%d", pcap_pkt_hdr_mem.tv_usec);
    $display ("caplen =%d", pcap_pkt_hdr_mem.caplen);
    $display ("len =%d", pcap_pkt_hdr_mem.len);

    pcap_payload_len = pcap_pkt_hdr_flat[31:0];
    pcap_payload_end_addr =  pcap_payload_offset + pcap_payload_offset;

    #150;
    $display ("2");
    for ( i = pcap_payload_offset; i < pcap_payload_end_addr ; i = i + 1) begin 
        repeat(1) @(posedge clk) addr_to_eth_ram = i; we_to_eth_ram = 1; cs_0 = 1; oe_to_eth_ram = 0; tb_data = temp_mem[i];
        $display ("ram_dp_inp_data %h", tb_data);
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
