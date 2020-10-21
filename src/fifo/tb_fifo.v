// create test bench
module tb_fifo(); 

reg reset;
reg [7:0] inp_d;
reg inp_clk;
reg out_clk;
wire [7:0] out_d;
reg read_flg;
reg write_flg;
integer j;

// instance of the module 
fifo dut( .out_d(out_d), .out_clk(inp_clk), .read_flg(read_flg), 
    .inp_clk(inp_clk), .inp_d(inp_d), .write_flg(write_flg), .reset(reset));

// reset the vriable & provide clock 
initial begin 
    inp_clk <= 0;
    out_clk <= 0;
    read_flg <=0;
    write_flg <=0;
    forever #10 inp_clk =~inp_clk;
    forever #10 out_clk =~out_clk;
end

// provide input to the module 
initial begin 
    #10;
    reset <= 0;
    #10
    reset <= 1;     //reset the module
    #10
    write_flg <= 1; //write start
    #10;
    for (j=0; j < 4 ; j=j+1) 
    begin
        inp_d <= j; 
        #20;
    end
    #10;
    write_flg <= 0; // write complete
    #10
    read_flg <= 1; // read start 
    #100
    read_flg <= 0; // read end
    #20
    $finish;
end

// dump the output 
initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,inp_d);
    $dumpvars(0,inp_clk);
    $dumpvars(0,out_d);
    $dumpvars(0,out_clk);
    $dumpvars(0,reset);
    $dumpvars(0,dut);
end

endmodule
