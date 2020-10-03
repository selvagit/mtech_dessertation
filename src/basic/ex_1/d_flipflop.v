// test project for revising the verilog

module  d_flipflop ( out_q , clk , inp_d);

input wire inp_d;
input wire clk;
output reg out_q;

always @(posedge clk)
begin
    out_q <= inp_d;
end

endmodule


