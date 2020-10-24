module tb_ram_dual_port ();
parameter ADDR_WIDTH = 16;
parameter DATA_WIDTH = 8;
parameter DEPTH = 16;

reg clk;

reg cs_0;
reg we_0;
reg oe_0;

reg cs_1;
reg we_1;
reg oe_1;

reg [ADDR_WIDTH-1:0] addr_0;
wire [DATA_WIDTH-1:0] data_0;

reg [ADDR_WIDTH-1:0] addr_1;
wire [DATA_WIDTH-1:0] data_1;

reg [DATA_WIDTH-1:0] tb_data;

integer i;

ram_dp_sr_sw dut ( 
    .clk(clk),
    .address_0(addr_0),
    .data_0(data_0),
    .cs_0(cs_0),
    .we_0(we_0),
    .oe_0(oe_0),
    .address_1(addr_1),
    .data_1(data_1),
    .cs_1(cs_1),
    .we_1(we_1),
    .oe_1(oe_1)
);

always #10 clk = ~clk;
assign data_0 = !oe_0 ? tb_data : 'hz;

initial begin 
    { clk, tb_data} <= 0; 
    { cs_0, we_0, addr_0, oe_0} <= 0; 
    { cs_1, we_1, addr_1, oe_1} <= 0; 

    repeat(2) @(posedge clk);

    $display ("first port");

    for ( i = 0; i < 10; i = i + 1) begin 
        repeat (1) @(posedge clk)  addr_0 <= i; we_0 <= 1; cs_0 <= 1; oe_0 <= 0; tb_data <= $random;
        $display ("ram_dp_inp_data %d %d ", tb_data, data_0);
    end

    $display ("second port");

    for ( i = 0; i < 10; i = i + 1) begin 
        repeat (1) @(posedge clk)  addr_1 <= i; we_1 <= 0; cs_1 <= 1; oe_1 <= 1; 
        $display ("ram_dp_out_data %d", data_1);
    end

    #200 $finish ;
end

initial begin
    $dumpfile("test_ram_dual_port.vcd");
    $dumpvars(0,dut);
    $dumpflush;
end

endmodule
