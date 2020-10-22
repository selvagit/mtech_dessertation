// the code was taken from the link https://www.chipverify.com/verilog/verilog-single-port-ram 
// single_port_sync_ram
module ecpri_ram 
# ( parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 256
)
( 
    input  clk,
    input [ADDR_WIDTH-1:0] addr,
    inout [DATA_WIDTH-1:0] data,
    input  cs,
    input  we, 
    input  oe
);

reg [DATA_WIDTH-1:0] tmp_data;
reg [DATA_WIDTH-1:0] mem [DEPTH];

always @ (posedge clk) begin 
    if (cs & we) begin 
        mem[addr] <= data;
        $display ("input data =%d", data, addr );
    end
end

always @ (posedge clk) begin 
    if (cs & !we) begin
        tmp_data <= mem[addr] ;
        $display ("output =%d %d", data, addr);
    end
end

assign data = cs & oe & !we ? tmp_data : 'hz;

endmodule
