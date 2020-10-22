
	// ram will be better option between the rx and tx module , since the 
	// mac, ip & port of the src and address address has to be swapped 


	/* get the data from the ram/fifo 
	*/
   module ecpri_tx ( to_switch, data_to_mem, send_write_resp, send_read_resp,
	   clk, rx_buff, tx_payload_len, reset);

   input wire reset;
   input wire [7:0] rx_buff;
   input wire clk;
   input wire send_write_resp;
   input wire send_read_resp;
   input wire [7:0] tx_payload_len;
   output reg [7:0] data_to_mem;
   output reg [7:0] to_switch;

   reg [7:0] inp_addr;

   always @(posedge reset)
   begin
       data_to_mem <= 0;
       to_switch <= 0;
   end

   always @(posedge clk) begin
   if (send_write_resp ) begin
    inp_addr <= rx_buff; 
    data_to_mem <= rx_buff;
    to_switch <= to_switch;
   end
    if (send_read_resp ) begin
    inp_addr <= tx_payload_len;
    to_switch <= inp_addr;
    
   end

   end

   endmodule
