// create test bench
module tb_ecpri();

parameter DATA_WIDTH = 8 ;
parameter ADDR_WIDTH = 16 ;

reg send_write_resp, send_read_resp; 
reg [DATA_WIDTH-1:0] resp_payload_len; 

reg [ADDR_WIDTH-1:0] addr_0;
reg [DATA_WIDTH-1:0] data_0; 
reg we_0, oe_0; //info_to_tx, 

reg [ADDR_WIDTH-1:0] addr_1;
reg [DATA_WIDTH-1:0] data_1; 
reg we_1, oe_1; 

reg [ADDR_WIDTH-1:0] addr_2; 
reg [DATA_WIDTH-1:0] data_2; 
reg we_2, oe_2; //data_to_mem,   

reg clk; 
reg [DATA_WIDTH-1:0] inp_data_fifo; 
reg recv_pkt, reset;

integer j;

ecpri_rx dut_ecpri_rx(
    send_write_resp, send_read_resp, resp_payload_len, 
    addr_0, data_0, we_0, oe_0, //info_to_tx, 
    addr_1, data_1, we_1, oe_1, 
    addr_2, data_2, we_2, oe_2, //data_to_mem,   
    clk, inp_data_fifo, recv_pkt, reset
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
