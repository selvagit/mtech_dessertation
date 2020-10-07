// test project for revising the verilog

module  fifo ( out_d, out_clk , inp_clk, inp_d, reset);

input wire reset;
input wire[7:0] inp_d;
input wire inp_clk;
input wire out_clk;
output reg[7:0] out_d;
  
reg [32:0] buffer[8];

reg [7:0] inp_addr;
reg [7:0] out_addr;

always @(posedge reset)
begin
    inp_addr <= 0;
    out_addr <= 0;
end

always @(posedge inp_clk)
begin
    buffer[inp_addr] <= inp_d;
    inp_addr <= inp_addr + 1;
end

always @(posedge out_clk)
begin
    out_d <= buffer[out_addr];
    out_addr <= out_addr + 1;
end

endmodule


