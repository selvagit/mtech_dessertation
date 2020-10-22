module tb_ram ();
parameter ADDR_WIDTH = 16;
parameter DATA_WIDTH = 8;
parameter DEPTH = 16;

reg clk;
reg cs;
reg we;
reg oe;

reg [ADDR_WIDTH-1:0] addr;
wire [DATA_WIDTH-1:0] data;
reg [DATA_WIDTH-1:0] tb_data;
integer i;

//ram #(.DATA_WIDTH(DATA_WIDTH)) dut 
ecpri_ram dut ( 
    .clk(clk),
    .addr(addr),
    .data(data),
    .cs(cs),
    .we(we),
    .oe(oe)
);

always #10 clk = ~clk;
assign data = !oe ? tb_data : 'hz;

initial begin 
    $dumpon; 
    { clk, cs, we, addr, tb_data, oe} <= 0; 

    repeat(2) @(posedge clk);

    for ( i = 0; i < 10; i = i + 1) begin 
        repeat (1) @(posedge clk)  addr <= i; we <= 1; cs <= 1; oe <= 0; tb_data <= $random;
        $display ("data =%d", tb_data);
    end

    for ( i = 0; i < 10; i = i + 1) begin 
        repeat (1) @(posedge clk)  addr <= i; we <= 0; cs <= 1; oe <= 1; 
    end

    #200 $finish ;
    $dumpoff; 
end

initial begin
    $dumpfile("test_ram.vcd");
    $dumpall;
    /*
    $dumpvars(0,clk);
    $dumpvars(0,addr);
    $dumpvars(0,data);
    $dumpvars(0,cs);
    $dumpvars(0,we);
    $dumpvars(0,oe);
    $dumpvars(0,dut);
    */
end

endmodule
