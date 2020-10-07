// create test bench
module tb_fifo();

reg reset;
reg [7:0] inp_d;
reg inp_clk;
reg out_clk;
wire [7:0] out_d;

// instance of the module 
fifo dut( .out_d(out_d), .out_clk(inp_clk), .inp_clk(inp_clk), .inp_d(inp_d), .reset(reset));

// provide clock 
initial 
begin 
inp_clk <= 0;
out_clk <= 0;
forever #10 inp_clk =~inp_clk;
forever #10 out_clk =~out_clk;
end

// provide input to the module 
initial 
begin 
#50;
reset <= 0;
#50
inp_d <= 0;
#10;
inp_d <= 8;
#10;
inp_d <= 0;
#50;
$finish;
end

// dump the output 
initial
begin
	$dumpfile("test.vcd");
	$dumpvars(0,inp_d);
	$dumpvars(0,inp_clk);
	$dumpvars(0,out_d);
	$dumpvars(0,out_clk);
	$dumpvars(0,reset);
	$dumpvars(0,dut);
end

endmodule
