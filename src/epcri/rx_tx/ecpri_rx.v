// test project for revising the verilog

module  ecpri_rx ( tx_payload_len, info_to_tx, data_to_mem, send_write_resp, send_read_resp,
                    clk, rx_buff, read_flg, reset);
input wire reset;
input wire[7:0] rx_buff;
input wire clk;
input wire read_flg;
output reg send_write_resp;
output reg send_read_resp;
output reg [7:0] info_to_tx;
output reg [7:0] tx_payload_len;
output reg [7:0] data_to_mem;

reg [7:0] inp_addr;
reg [7:0] payload_len;

reg [7:0] state;
reg [7:0] nextstate;     
reg [7:0] inp_d;     
reg [7:0] dst_addr;     
reg [7:0] info_to_rx;

parameter  eth_hdr_offset = 0;
parameter  eth_hdr_len = 14;
parameter  ip_hdr_offset = 14;
parameter  ip_hdr_len = 20;
parameter  udp_hdr_start = 34;
parameter  udp_hdr_len = 8;
parameter  vlan_offset = 0;

parameter  reset_rx = 0;
parameter  cpri_hdr = 1;
parameter  cpri_type = 2;
parameter  read_id = 3;
parameter  read_mem = 4;
parameter  read_payload = 6;
parameter  raise_rx_resp = 7;
parameter  write_id = 8;
parameter  write_mem = 9;
parameter  write_payload = 10;
parameter  write_to_mem = 11;
parameter  raise_tx_resp = 12;

// always block to update state 
always @(posedge clk or posedge reset) begin   
    if (reset) begin      
        state <= reset_rx; 
        inp_addr <= 0;
        payload_len <= 0;
        send_write_resp <= 0;
        send_read_resp <= 0;
    end
    else begin
        state <= nextstate; 
    end
end

// always block for doing the state activity
always @(state)  begin
    case (state)
        reset_rx :begin end
        cpri_hdr :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        cpri_type :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        read_id :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        read_mem :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        read_mem :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        read_payload :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        raise_rx_resp :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        write_id :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        write_mem :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        write_payload :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        write_to_mem :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
        raise_tx_resp :begin info_to_rx = inp_d; inp_addr = inp_addr + 1;  end
    endcase
end	

// always block to compute nextstate 
always @(clk or state or rx_buff or read_flg) begin    
    nextstate = reset_rx;     
    case (state)
        reset_rx: begin
            if (read_flg) begin 
                nextstate = cpri_hdr;
                inp_addr = rx_buff + udp_hdr_start + udp_hdr_len ;
            end
        end

        cpri_hdr: begin  // check the ecpri write flag is set 
        if (inp_d == 8'h10) begin         
            nextstate = cpri_type;
        end
    end

    cpri_type: begin
        if (inp_d == 8'h10) begin        // check the write flag
            nextstate = write_id;
        end
        if (inp_d == 8'h00) begin        // check the read flag
            nextstate = read_id;
        end
    end

    read_id:  begin 
    if (inp_d == 8'h00) begin
        nextstate = read_mem;
    end
end

read_mem : begin
    nextstate = read_payload;
    dst_addr = inp_d;
    tx_payload_len = payload_len;
end

read_payload : begin
    if (inp_addr == 8'h12) begin
        payload_len  = inp_d;
        nextstate = raise_rx_resp;
    end
end

raise_rx_resp : begin
    send_read_resp = 1;
    nextstate = reset_rx;
end

write_id : begin
end

write_mem : begin
    // get the dst_address memory address 
    if (inp_addr == 8'h13) begin
        dst_addr = inp_d;
        tx_payload_len = payload_len;
    end
end

write_payload : begin
    // get the length of the payload 
    if (inp_addr == 8'h12) begin
        payload_len  = inp_d;
    end
end

write_to_mem : begin
    // copy the payload 
    if ( payload_len > 8'h0) begin
        dst_addr = inp_d;
        payload_len = payload_len - 1;
        dst_addr = dst_addr + 1;
        data_to_mem = 'h1;
        info_to_tx = 'h1;
    end
end

raise_tx_resp : begin
    send_write_resp <= 1;
    nextstate = reset_rx;
end

default : begin
end
endcase
end

endmodule //ecpri_rx

