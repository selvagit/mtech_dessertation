
`timescale 1 us / 1 ns

//-----------------------------------------------------
// Design Name : ecpri
// File Name   : ecpri_rx.v
// Function    : module to handle epcri rx packet 
// Coder       : selvaraj 
//-----------------------------------------------------
module  ecpri_rx ( send_write_resp, send_read_resp, resp_payload_len, 
                    addr_0, data_0, we_0, oe_0, // data to the eth packet header  
                    addr_1, data_1, we_1, oe_1, // data from eth ram  
                    addr_2, data_2, we_2, oe_2, // data to the cpri payload 
                    clk, inp_data_fifo, recv_pkt, reset);

parameter DATA_WIDTH = 8 ;
parameter ADDR_WIDTH = 16 ;

//--------------Input Ports----------------------- 
input wire reset;
input wire [DATA_WIDTH-1:0] inp_data_fifo;
input wire clk;
input wire recv_pkt;

//--------------Out Ports----------------------- 
output reg send_write_resp;
output reg send_read_resp;
output reg [DATA_WIDTH-1:0] resp_payload_len;

// port to copy the ethernet packet 
output reg [ADDR_WIDTH-1:0] addr_0;
output reg [DATA_WIDTH-1:0] data_0;
output reg we_0;
output reg oe_0;

// port to transfer, unused port in current implementation 
output reg [ADDR_WIDTH-1:0] addr_1;
input wire [DATA_WIDTH-1:0] data_1;
output reg we_1;
output reg oe_1;

// port to tranfer the ecpri paload 
output reg [ADDR_WIDTH-1:0] addr_2;
output reg [DATA_WIDTH-1:0] data_2;
output reg we_2;
output reg oe_2;

//--------------Internal variables---------------- 
reg [ADDR_WIDTH-1:0] inp_addr;
reg [ADDR_WIDTH-1:0] dst_addr;     

reg [ADDR_WIDTH-1:0] payload_len;
reg [DATA_WIDTH-1:0] inp_d;     

reg [7:0] state;
reg [7:0] nextstate;     
reg [7:0] info_to_rx;

//-------------- Ethernet header offset and length ----------------------- 
parameter  eth_hdr_offset = 0;
parameter  eth_hdr_len = 14;
parameter  ip_hdr_offset = 14;
parameter  ip_hdr_len = 20;
parameter  udp_hdr_start = 34;
parameter  udp_hdr_len = 8;
parameter  vlan_offset = 0;

//-------------- ecpri state machine ------------------------------ 
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

//-------------- ecpri state machine ------------------------------ 
// always block to update state 
always @(posedge clk or posedge reset) begin   
    if (reset) begin      
        //$display(" ecpri_rx:doing reset");
        state <= reset_rx; 
        inp_addr <= 0;
        payload_len <= 0;
        send_write_resp <= 0;
        send_read_resp <= 0;
        send_write_resp <=0; 
        send_read_resp <= 0; 
        resp_payload_len <= 0;
        addr_0 <=0; 
        data_0 <=0;
        we_0 <=0; 
        oe_0 <=0; 
        addr_1 <= 0;
        we_1 <= 0;
        oe_1 <= 0;
        addr_2 <= 0;
        data_2 <= 0;
        we_2 <= 0;
        oe_2 <= 0;
    end
    else begin
        //$display(" ecpri_rx:no_reset");
        if ( recv_pkt == 1'b1 ) ; begin
            state <= nextstate; 

            addr_1 <= addr_1 + 1;  
            inp_d  <= data_1; 

            addr_0 <= addr_0 + 1; 
            data_0 <= data_1;

            oe_1 <= 1;
        end
    end
end

// always block for doing the state activity
// increment the address in every state to get the data 
// for every cycle 
always @(state)  begin
    case (state)
        reset_rx :begin 
            //
        end
        cpri_hdr :begin
            
		end
        cpri_type :begin
		   
            
		end
        read_id :begin
		   
            
		end
        read_mem :begin
		   
            
		end
        read_payload :begin
		   
            
		end
        raise_rx_resp :begin
		   
            
		end
        write_id :begin
		   
            
		end
        write_mem :begin
		   
            
		end
        write_payload :begin
		   
            
		end
        write_to_mem :begin
		   
            
		end
        raise_tx_resp :begin
		   
            
     end
    endcase
end	

// always block to compute nextstate 
always @(clk or state or recv_pkt) begin    
    case (state)
        reset_rx: begin
            //
            if (recv_pkt) begin 
                nextstate <= cpri_hdr;
            end
        end

        cpri_hdr: begin  // check the ecpri write flag is set 
            
            if (inp_d == 8'h10) begin         
                nextstate <= cpri_type;
                
            end
        end

        cpri_type: begin
            
            if (inp_d == 8'h10) begin        // check the write flag
                nextstate <= write_id;
            end
            if (inp_d == 8'h00) begin        // check the read flag
                nextstate <= read_id;
            end
        end

        read_id:  begin 
            
            if (inp_d == 8'h00) begin
                nextstate <= read_mem;
            end
        end

        read_mem : begin
            
            nextstate <= read_payload;
            dst_addr <= inp_d;
            resp_payload_len <= payload_len;
        end

        read_payload : begin
            
            if (inp_addr == 8'h12) begin
                payload_len  <= inp_d;
                nextstate <= raise_rx_resp;
            end
        end

        raise_rx_resp : begin
            
            send_read_resp <= 1;
            nextstate <= reset_rx;
        end

        write_id : begin
            
        end

        write_mem : begin
            
            // get the dst_address memory address 
            if (inp_addr == 8'h13) begin
                dst_addr <= inp_d;
                resp_payload_len <= payload_len;
            end
        end

        write_payload : begin
            
            // get the length of the payload 
            if (inp_addr == 8'h12) begin
                payload_len  <= inp_d;
            end
        end

        write_to_mem : begin
            
            // copy the payload 
            if ( payload_len > 8'h0) begin
                dst_addr <= inp_d;
                payload_len <= payload_len - 1;
                dst_addr <= dst_addr + 1;
                data_2 <= 'h1;
                data_0 <= 'h1;
            end
        end

        raise_tx_resp : begin
            
            send_write_resp <= 1;
            nextstate <= reset_rx;
        end

        default : begin
            
        end
    endcase
end

endmodule //ecpri_rx

