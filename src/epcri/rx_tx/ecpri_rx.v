// test project for revising the verilog

module  epcri_rx ( tx_payload_len, info_to_tx, data_to_mem, send_write_resp, sen_read_resp,
                    clk, rx_buff, read_flg, reset);
input wire reset;
input wire[7:0] rx_buff;
input wire inp_clk;
input wire read_flg;
output wire send_write_resp;
output wire read_write_resp;
output reg[7:0] info_to_tx;

reg [7:0] inp_addr;
integer payload_len;

reg state, nextstate;     

parameter  reset_rx = 0;
parameter  cpri_hdr = 1;
parameter  cpri_type = 2;
parameter  read = 3;
parameter  read_mem = 4;
parameter  read_mem = 5;
parameter  read_payload = 6;
parameter  raise_rx_resp = 7;
parameter  write = 8;
parameter  write_mem = 9;
parameter  write_payload = 10;
parameter  write_to_mem = 11;
parameter  raise_tx_resp = 12;

always @(posedge clk or posedge reset)    // always block to update state 
	if (reset)
	begin      
	state <= rest_rx; 
	inp_addr <= 0;
	payload_len <= 0;
	send_write_resp <= 0;
	read_write_resp <= 0;
end
else
	state <= nextstate; 


always @(state)
begin 
case (state)
  reset_rx :
  cpri_hdr :
  cpri_type :
  read :
  read_mem :
  read_mem :
  read_payload :
  raise_rx_resp :
  write :
  write_mem :
  write_payload :
  write_to_mem :
  raise_tx_resp :
	endcase
end	

always @(state or rx_buff or read_flg)        // always block to compute nextstate 
begin    

nextstate = reset_rx;     
case (state)
    reset_rx :
        if (read_flg)
        begin
            info_to_rx <= inp_d;                // put the packet to the tx fifo 
            inp_addr <= inp_addr + 1;           // increment the current pos
        end

        cpri_hdr :
        begin
            info_to_rx <= inp_d;                // put the packet to the tx fifo 
            inp_addr <= inp_addr + 1;           // increment the current pos
            // check the socket is matching
            if (inp_addr == 0x10)               // check the ecpri write flag is set 
            begin

            end
        end

        cpri_type :
        begin
            if (inp_d == 0x10) begin        // check the write flag
                send_write_resp <= 1;
            end
            if (inp_d == 0x00) begin        // check the read flag
                send_read_resp <= 1;
            end

        end
        read :
        begin 
    end
    read_mem :
    begin
        // get the dst_address memory address 
        if (inp_addr == 0x13)
        begin
            dst_addr <= inp_d;
            tx_payload_len <= payload_len;
        end
    end

    read_payload :
    begin
        // get the length of the payload 
        if (inp_addr == 0x12)
        begin
            payload_len  <= inp_d;
        end
    end

    raise_rx_resp :
    begin
    end

    write :
    begin
    end

    write_mem :
    begin
        // get the dst_address memory address 
        if (inp_addr == 0x13)
        begin
            dst_addr <= inp_d;
            tx_payload_len <= payload_len;
        end
    end

    write_payload :
    begin
        // get the length of the payload 
        if (inp_addr == 0x12)
        begin
            payload_len  <= inp_d;
        end
    end

    write_to_mem :
    begin
        // copy the payload 
        if ( payload_len > 0)
        begin
            dst_addr <= inp_d;
            payload_len <= payload_len - 1;
            dst_addr <= dst_addr + 1;
        end
    end

    raise_tx_resp :
    begin
    end

endcase
end


endmodule //ecpri_rx

