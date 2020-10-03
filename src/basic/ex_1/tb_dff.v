// create test bench
module tb_dff();

reg inp_d;
reg clk;
wire out_q;

// instance of the module 
d_flipflop dut( out_q , clk , inp_d);

// provide clock 
initial 
begin 
clk = 0;
forever #10 clk =~clk;
end

// provide input to the module 
initial 
begin 
inp_d <= 0;
#100;
inp_d <= 1;
#100;
inp_d <= 0;
#100;
$finish;
end

// dump the output 
initial
begin
	$dumpfile("test.vcd");
	$dumpvars(0,inp_d);
	$dumpvars(0,clk);
	$dumpvars(0,out_q);
end

endmodule
