
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
reg [DATA_WIDTH-1:0] inp_d;     
reg [DATA_WIDTH-1:0] prev_d;     

reg [7:0] state;
reg [7:0] next_state;     
reg [7:0] info_to_rx;

reg [7:0] ecpri_hdr_offset;
reg [7:0] ecpri_remote_mem_hdr_offset;

reg [7:0] ecpri_ver;
reg [7:0] ecpri_msg_type;
reg [15:0] ecpri_payload_len;

reg [7:0] ecpri_remote_acc_id;
reg [7:0] ecpri_rm_rw_req_resp;
reg [15:0] ecpri_rm_ele_id;
reg [47:0] ecpri_rm_addr;
reg [15:0] ecpri_rm_len;

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
parameter  find_cpri_hdr = 1;
parameter  read_cpri_hdr = 2;
parameter  read_cpri_remote_mem_hdr = 3;
parameter  cpri_type = 4;
parameter  cpri_remote_memory = 5;
parameter  read_payload = 8;
parameter  raise_rx_resp = 9;
parameter  write_id = 10;
parameter  write_mem = 11;
parameter  write_to_mem = 13;
parameter  raise_tx_resp = 14;

//-------------- ecpri state machine ------------------------------ 
// always block to update state 
always @(posedge clk or posedge reset) begin   
    if (reset) begin      
        //$display(" ecpri_rx:doing reset");
        state <= reset_rx; 
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
        next_state <= reset_rx;
        ecpri_hdr_offset  <= 0;
        ecpri_ver <= 0;
        ecpri_msg_type <= 0;
        ecpri_payload_len <= 0;

        ecpri_remote_acc_id <= 0;
        ecpri_rm_rw_req_resp <= 0;
        ecpri_rm_ele_id <= 0;
        ecpri_rm_addr <= 0;
        ecpri_rm_len <= 0;
    end
    else begin
        if ( recv_pkt == 1'b1 ) ; begin
            state <= next_state; 

            addr_1 <= addr_1 + 1;  
            prev_d <= data_1; 

            oe_1 <= 1;

            addr_0 <= addr_0 + 1; 
            data_0 <= data_1;
        end
    end
end

// always block for doing the state activity
// increment the address in every state to get the data 
// for every cycle 
always @(posedge state)  begin
    case (state) 
        reset_rx :begin 
        end

        find_cpri_hdr: begin
            we_0 <= 1;
            oe_0 <= 0;
        end

        read_payload :begin
		end

        raise_rx_resp :begin
		end

        write_to_mem :begin
            we_2 <= 1;
            oe_2 <= 0;
		end

        raise_tx_resp :begin
        end
    endcase
end	

// always block to compute next_state 
always @(posedge clk) begin    
    case (next_state)
        reset_rx: begin
            if (recv_pkt) begin 
                next_state <= find_cpri_hdr;
            end
        end

        find_cpri_hdr: begin  // check the ecpri write flag is set 
            if ( ((prev_d << 8) | data_1) == 16'haefe) begin         
                next_state <= read_cpri_hdr;
            end
        end

        read_cpri_hdr: begin
            if (ecpri_hdr_offset == 8'h0) begin
               ecpri_ver <= data_1;
            end else 

            if (ecpri_hdr_offset == 8'h1) begin
               ecpri_msg_type <= data_1;
            end else 

            if (ecpri_hdr_offset == 8'h2) begin
                ecpri_payload_len [15:8] <= data_1;
            end else

            if (ecpri_hdr_offset == 8'h3) begin
                ecpri_payload_len [7:0] <= data_1;
                next_state <= read_cpri_remote_mem_hdr;
                ecpri_remote_mem_hdr_offset <= 0;
            end

            ecpri_hdr_offset <= ecpri_hdr_offset + 1;
        end

        read_cpri_remote_mem_hdr: begin
            if (ecpri_msg_type != 8'h4) begin
              next_state <= reset_rx;
            end else begin
                if (ecpri_remote_mem_hdr_offset == 8'h0) begin        
                    ecpri_remote_acc_id <= data_1;
                end

                if (ecpri_remote_mem_hdr_offset == 8'h1) begin        
                    ecpri_rm_rw_req_resp <= data_1;
                end

                if ((ecpri_remote_mem_hdr_offset == 8'h2) || (ecpri_remote_mem_hdr_offset == 8'h3)) begin        
                    ecpri_rm_ele_id <= (ecpri_rm_ele_id << 8'h8) | data_1;
                end

                if ((ecpri_remote_mem_hdr_offset > 8'h3)  &&  (ecpri_remote_mem_hdr_offset < 8'ha) ) begin        
                    ecpri_rm_addr <= (ecpri_rm_addr << 8'h8) | data_1;
                end

                if ((ecpri_remote_mem_hdr_offset == 8'ha)  ||  (ecpri_remote_mem_hdr_offset == 8'hb)) begin        
                    ecpri_rm_len <= (ecpri_rm_len << 8'h8) | data_1;
                end

                if (ecpri_remote_mem_hdr_offset == 8'hb) begin
                    if ( ecpri_rm_rw_req_resp == 8'h0) begin
                        next_state <= read_payload;
                    end else begin
                        next_state <= write_to_mem; 
                        addr_2 <= 0; 
                    end
                end

                ecpri_remote_mem_hdr_offset  <= ecpri_remote_mem_hdr_offset + 1;
            end
        end

        read_payload : begin
            resp_payload_len  <= ecpri_rm_len[7:0] ;
            next_state <= raise_rx_resp;
        end

        raise_rx_resp : begin
            send_read_resp <= 1;
            next_state <= reset_rx;
        end

        write_to_mem : begin
            // copy the payload 
            if ( ecpri_rm_len > 8'h0) begin
                ecpri_rm_len <= ecpri_rm_len - 1;
                addr_2 <= addr_2 + 1;
                data_2 <= data_1;
            end
        end

        raise_tx_resp : begin
            send_write_resp <= 1;
            next_state <= reset_rx;
        end

        default : begin
        end
    endcase
end

endmodule //ecpri_rx


        
