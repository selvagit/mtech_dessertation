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
reg [DATA_WIDTH-1:0] tb_data_out;

reg [31:0] i;
reg [31:0] j;

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

pcap_file_hdr pcap_file_hdr_mem;
pcap_pkt_hdr  pcap_pkt_hdr_mem;

reg [31:0] pcap_file_hdr_flat [$bits(pcap_file_hdr)/32];
reg [31:0] pcap_pkt_hdr_flat [$bits(pcap_pkt_hdr)/32]; 

integer return_value ;

reg [31:0] temp ;
reg [31:0] payload_len;

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
    i=0;
    j=0;

    #20;
    $display (" tb: state 0");
    fd = $fopen("../gen_pcap/remote_memory_access.pcap","rb"); 
    if ( fd ) begin 
        $display (" tb: pcap file was opened");
        fdw = $fopen("cp_ecpri.pcap","wb"); 
    end else begin
        errorno = $ferror(fd, err_str);
        $display (" tb: pcap file could not be opened %s", err_str);
        $finish; // end simulation
    end 
    eof = $fread(temp_mem,fd);
    $fclose (fd);
    $display (" tb: File closed");
    
    #50;
    $display (" tb: state 1");
    pcap_file_hdr_len = $bits(pcap_file_hdr);
    pcap_pkt_hdr_len = $bits(pcap_pkt_hdr);
    $display( "Size of pcap global header = %d %d", pcap_file_hdr_len,  pcap_file_hdr_len/8);
    $display( "Size of per packet header = %d %d", pcap_pkt_hdr_len, pcap_pkt_hdr_len/8);

    pcap_payload_offset = pcap_file_hdr_len/8 + pcap_pkt_hdr_len/8;
    $display("tb: payload offet = %d", pcap_payload_offset);

    fd = $fopen("../gen_pcap/ecpri.pcap","rb"); 
    return_value = $fread(pcap_file_hdr_flat,fd);
    $display (" tb: file hdr bits len =%d", return_value);

    return_value = $fread(pcap_pkt_hdr_flat,fd);
    $display (" tb: pkt hdr bits len =%d", return_value);

    $fclose(fd);

    $display (" tb: magic =%h", pcap_file_hdr_flat[0]);
    $display (" tb: snaplen =%h", pcap_file_hdr_flat[4]);
    $display (" tb: linktype =%h", pcap_file_hdr_flat[5]);

    temp = pcap_pkt_hdr_flat[3];
    payload_len = temp[31:24] ;

    temp = pcap_payload_offset + payload_len;

    $display (" tb: pcap_payload_len = %h", payload_len);

    #50; // push the data into the eth_ram 
    $display (" tb: state 2");
    for ( i = pcap_payload_offset; i < temp ; i = i + 1) begin 
        repeat(1) @(posedge clk) addr_to_eth_ram = j; we_to_eth_ram = 1; cs_0 = 1; oe_to_eth_ram = 0; tb_data = temp_mem[i]; j = j + 1;
        //$display (" tb: ram_dp_inp_data %h", tb_data);
    end

    /*
    #350; // check the data is in the eth_ram 
    $display (" tb: state 3");
    for ( j = 0; j < payload_len ; j = j + 1) begin 
        $display (" ram internal mem[%d] = %h", j, ram_recv_eth_packet.mem[j]);
    end

    #50 ; // read the ram data port 0
    for ( i = 0; i < payload_len ; i = i + 1) begin 
        repeat(1) @(posedge clk) addr_to_eth_ram = i; we_to_eth_ram = 0; cs_0 = 1; oe_to_eth_ram = 1; tb_data = data_to_eth_ram;
        $display (" tb: ram_dp_out_data %h", tb_data);
    end
    */

    #100 // reset the epcri_rx module
    $display (" tb: state 4");
    repeat (1) @(posedge clk) reset = 1;

    #50 
    $display (" tb: state 5");
    repeat (1) @(posedge clk) reset = 0;

    #50; // provide signals to the ecpri_rx module 
    $display (" tb: state 6");
    for ( i = 0 ; i < payload_len; i = i + 1) begin 
        repeat(1) @(posedge clk) recv_pkt <= 1; cs_1 <= 1; cs_0 <= 0; oe_to_eth_ram <= 0;    
    end

    $finish;
end

// dump the output 
initial begin
    $dumpfile("ecpri.vcd");

    $dumpvars(0,tb_ecpri);
    $dumpvars(0,ram_recv_eth_packet);
    $dumpvars(0,dut_ecpri_rx);
    $dumpvars(0,ram_cpri_payload);

    $monitor ("data_1 = %h address_1 = %h data_1_out = %h", ram_recv_eth_packet.data_1 , ram_recv_eth_packet.address_1, ram_recv_eth_packet.data_1_out);
    $monitor ("we_1 = %h oe_1 = %h addr_1 = %h data_1 = %h inp_d = %h state = %d nextstate =%d", 
        dut_ecpri_rx.we_1, dut_ecpri_rx.oe_1, dut_ecpri_rx.addr_1, dut_ecpri_rx.data_1, dut_ecpri_rx.inp_d, dut_ecpri_rx.state, dut_ecpri_rx.next_state);
    //$monitor ("cpri_marker = %h ", dut_ecpri_rx.cpri_marker);
end

endmodule
