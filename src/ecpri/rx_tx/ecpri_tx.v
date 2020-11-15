
`timescale 1 us / 1 ns

// ram will be better option between the rx and tx module , since the 
// mac, ip & port of the src and address address has to be swapped 


/* get the data from the ram/fifo 
*/
module ecpri_tx ( cpri_pkt_rdy_flg, 
                addr_0, data_0, we_0, oe_0, // data from the cpri payload 
                addr_1, data_1, we_1, oe_1,  // data to the ram cpri packet   
                addr_2, data_2, we_2, oe_2,  // data from eth ram  
                send_write_resp, send_read_resp,
                clk, resp_payload_len, reset, recv_pkt);

//-- data and address width for the port 
parameter DATA_WIDTH = 8 ;
parameter ADDR_WIDTH = 16 ;

//--------------Input Ports----------------------- 

input wire reset;
input wire clk;
input wire recv_pkt;
input wire send_write_resp;
input wire send_read_resp;
input wire [7:0] resp_payload_len;

//--------------Output Ports----------------------- 
output reg cpri_pkt_rdy_flg;

// port to copy the cpri payload 
output reg [ADDR_WIDTH-1:0] addr_0;
input wire [DATA_WIDTH-1:0] data_0;
output reg we_0;
output reg oe_0;

// port to wite newly created packet 
output reg [ADDR_WIDTH-1:0] addr_1;
output reg [DATA_WIDTH-1:0] data_1;
output reg we_1;
output reg oe_1;

// dummy port 
output reg [ADDR_WIDTH-1:0] addr_2;
output reg [DATA_WIDTH-1:0] data_2;
output reg we_2;
output reg oe_2;

//--------------Internal variables ----------------------- 

//state variables
reg [7:0] state;
reg [7:0] next_state;     

reg [7:0] g_hdr_addr;
reg [7:0] l_rm_mem_hdr_addr;

reg [7:0] g_ver;
reg [7:0] g_msg_type;
reg [15:0] g_payload_len;

reg [7:0] l_rm_acc_id;
reg [7:0] l_rm_rw_req_resp;
reg [15:0] l_rm_ele_id;
reg [47:0] l_rm_addr;
reg [15:0] l_rm_len;

//---------- fsm stages ---------------------------------------
parameter reset_tx = 1;
parameter write_cpri_hdr = 2;
parameter write_cpri_remote_mem_hdr = 3; 
parameter read_payload = 4;   
parameter write_to_mem = 6;
parameter cpri_pkt_rdy = 7;

//------------- CPRI header offset and length  -------------
parameter g_hdr_offset = 0;
parameter g_hdr_len = 4;
parameter l_hdr_offset = 4;
parameter l_hdr_len = 12; 

//--------------Logic ----------------------- 
//always block to update state 
always @(posedge clk or posedge reset) begin   
    if (reset) begin      
        //$display(" ecpri_rx:doing reset");
        state <= reset_tx; 
        next_state <= reset_tx;

        addr_0 <=0; 
        we_0 <=0; 
        oe_0 <=0; 

        addr_1 <=0; 
        data_1 <=0;
        we_1 <=0; 
        oe_1 <=0; 

        addr_2 <=0; 
        data_2 <=0;
        we_2 <=0; 
        oe_2 <=0; 

        g_hdr_addr  <= 0;
        g_ver <= 0;
        g_msg_type <= 0;
        g_payload_len <= 0;

        l_rm_acc_id <= 0;
        l_rm_rw_req_resp <= 0;
        l_rm_ele_id <= 0;
        l_rm_addr <= 0;
        l_rm_len <= 0;
    end
    else begin
        if ( recv_pkt == 1'b1 ) ; begin
            state <= next_state; 

            if (next_state == read_payload ) begin
                addr_0 <= addr_0 + 1;  
                oe_1 <= 1;
            end

            addr_1 <= addr_1 + 1; 
            we_1 <= 1;
        end
    end
end

always @(posedge clk) begin    
    case (next_state)
        reset_tx: begin
            if (recv_pkt) begin 
                next_state <= write_cpri_hdr;
                g_payload_len <= resp_payload_len + 4 ;
            end
        end

         write_cpri_hdr: begin
            if (g_hdr_addr == 8'h0) begin
               data_1 <= 8'h10 ;
            end else 

            if (g_hdr_addr == 8'h1) begin
                data_1 <= 8'h4;
            end else 

            if (g_hdr_addr == 8'h2) begin
                data_1 <= g_payload_len [15:8];
            end else

            if (g_hdr_addr == 8'h3) begin
                data_1 <= g_payload_len [7:0];
                next_state <= write_cpri_remote_mem_hdr;
                l_rm_mem_hdr_addr <= 0;
            end

            g_hdr_addr <= g_hdr_addr + 1;
        end

        write_cpri_remote_mem_hdr: begin
                if (l_rm_mem_hdr_addr == 8'h0) begin        
                    data_1 <= l_rm_acc_id ;
                end

                if (l_rm_mem_hdr_addr == 8'h1) begin        
                    if (send_write_resp == 1'b1) begin
                        data_1 <= 8'h11;
                    end if (send_read_resp == 1'b1) begin
                        data_1 <= 8'h10;
                    end else begin
                        next_state <= reset_tx;
                    end
                end

                if (l_rm_mem_hdr_addr == 8'h2)  begin        
                    data_1 <= l_rm_ele_id [15:8];
                end

                if (l_rm_mem_hdr_addr == 8'h3) begin
                    data_1 <= l_rm_ele_id[7:0];
                end

                if ( (l_rm_mem_hdr_addr > 8'h3)  &&  (l_rm_mem_hdr_addr < 8'ha) ) begin        
                    data_1 <= l_rm_addr[47:40] ;
                end

                if ((l_rm_mem_hdr_addr == 8'ha)  ||  (l_rm_mem_hdr_addr == 8'hb)) begin        
                    data_1 <= l_rm_len [15:8];
                end

                if (l_rm_mem_hdr_addr == 8'hb) begin
                    if ( l_rm_rw_req_resp == 8'h0) begin
                        next_state <= read_payload;
                    end else begin
                        next_state <= write_to_mem; 
                        addr_1 <= 0; 
                    end
                end

                l_rm_mem_hdr_addr  <= l_rm_mem_hdr_addr + 1;
        end

        read_payload : begin
            // copy the payload 
            if ( l_rm_len > 8'h0) begin
                l_rm_len <= l_rm_len - 1;
                addr_1 <= addr_1 + 1;
                data_1 <= data_0;
            end else begin 
                next_state <= cpri_pkt_rdy;
            end
        end

        write_to_mem : begin
            //resp_payload_len  <= l_rm_len[7:0] ;
            next_state <= cpri_pkt_rdy;
        end

        cpri_pkt_rdy: begin
            cpri_pkt_rdy_flg  <= 1;
        end

        default : begin
        end
    endcase
end

endmodule //ecpri_tx

