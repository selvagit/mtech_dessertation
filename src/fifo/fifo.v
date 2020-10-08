// test project for revising the verilog

module  fifo ( out_d, out_clk, read_flg, inp_clk, inp_d, write_flg, reset);

input wire reset;
input wire[7:0] inp_d;
input wire inp_clk;
input wire out_clk;
input wire read_flg;
input wire write_flg;
output reg[7:0] out_d;

reg [32:0] buffer[8];

reg [7:0] inp_addr;
reg [7:0] out_addr;

integer j;

always @(posedge reset)
begin
    inp_addr <= 0;
    out_addr <= 0;
    for (j=0; j < 8 ; j=j+1) begin
        buffer[j] <= 8'b0; //reset array
    end
end

always @(posedge inp_clk)
begin
    if (write_flg)
    begin
        buffer[inp_addr] <= inp_d;
        inp_addr <= inp_addr + 1;
    end
end

always @(posedge out_clk) 
begin
    if (read_flg)
    begin
        out_d <= buffer[out_addr];
        out_addr <= out_addr + 1;
    end
end

endmodule


