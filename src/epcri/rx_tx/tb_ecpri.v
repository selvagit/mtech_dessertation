// create test bench
module tb_ecpri();

reg reset;
reg[7:0] rx_buff;
reg clk;
reg read_flg;
wire send_write_resp;
wire send_read_resp;
wire [7:0] info_to_tx;
wire [7:0] tx_payload_len;
wire [7:0] data_to_mem;
integer j;

ecpri_rx tb_ecpri_rx( tx_payload_len, info_to_tx, data_to_mem, send_write_resp, send_read_resp,
                    clk, rx_buff, read_flg, reset);

// reset the vriable & provide clock 
initial 
begin 
forever #10 clk =~clk;
end

// provide input to the module 
initial 
begin 
#10;
reset <= 0;
#20
$finish;
end

// dump the output 
initial
begin
    $dumpfile("test_ecpri.vcd");
    $dumpvars(0,tb_ecpri_rx);
end

endmodule
