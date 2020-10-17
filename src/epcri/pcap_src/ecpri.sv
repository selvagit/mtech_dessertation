`timescale 1 ns/1 ps

module dummy ( output [7:0] out [64] , 
    input [7:0] inp [64] , 
    input clk ) ;

reg [16:0] count;

initial 
begin
    count <= 0;
end

always @(posedge clk)
begin
    out[count] <= inp [count] + count;
    if ( count < 32 ) 
    begin
        count <= count + 1;
    end
    else
    begin
        count <= 0;
    end
end

endmodule 
