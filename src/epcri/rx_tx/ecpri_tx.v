
	// ram will be better option between the rx and tx module , since the 
	// mac, ip & port of the src and address address has to be swapped 


	/* get the data from the ram/fifo 
	*/
   module epcri_tx ( to_switch, data_to_mem, send_write_resp, sen_read_resp,
	   inp_clk, rx_buff, tx_payload_len, reset);

   input wire reset;
   input wire[7:0] rx_buff;
   input wire inp_clk;
   input wire out_clk;
   input wire send_write_resp;
   input wire read_write_resp;
   output reg[7:0] to_switch;

   reg [7:0] inp_addr;
   integer payload_len;
   integer pkt_hdr_len;

   always @(posedge reset)
   begin
	   inp_addr <= 0;
	   payload_len <= 0;
	   pkt_hdr_len <= 35; //2 ip, 2 mac, 2 port, 1 vlan id, 1 ipv4 header 
   end

   always @(posedge clk) 
   begin 
   if (send_write_resp)

	   //add the mac header 
   //
   // add the ether type  
   // 
   // add the ip header 
   //
   // add the ecpri header 
   //
   // add the packet payload 
   end

   endmodule
