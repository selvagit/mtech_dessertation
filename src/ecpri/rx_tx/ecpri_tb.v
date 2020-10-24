// create test bench
module tb_ecpri();

parameter DATA_WIDTH = 8 ;
parameter ADDR_WIDTH = 16 ;

output send_write_resp, send_read_resp; 
output [DATA_WIDTH-1:0] resp_payload_len; 

output [ADDR_WIDTH-1:0] addr_0;
output [DATA_WIDTH-1:0] data_0; 
output we_0, oe_0; //info_to_tx, 

output [ADDR_WIDTH-1:0] addr_1;
output [DATA_WIDTH-1:0] data_1; 
output we_1, oe_1; 

output [ADDR_WIDTH-1:0] addr_2; 
output [DATA_WIDTH-1:0] data_2; 
output we_2, oe_2; //data_to_mem,   

input clk; 
input [DATA_WIDTH-1:0] inp_data_fifo; 
input reg recv_pkt, reset;

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
    forever #10 clk =~clk;
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
