
`timescale 1ns / 1ps
`include "ecpri_v2_0_tb_include.svh"

import axi_vip_pkg::*;
import ecpri_v2_0_bfm_1_slave_0_0_pkg::*;
import ecpri_v2_0_bfm_1_master_0_0_pkg::*;
`define S_AXI_INTR_SLAVE_ADDRESS 32'h44A00000 

module ecpri_v2_0_tb();


xil_axi_uint                            error_cnt = 0;
xil_axi_uint                            comparison_cnt = 0;
axi_transaction                         wr_transaction;   
axi_transaction                         rd_transaction;   
axi_monitor_transaction                 mst_monitor_transaction;  
axi_monitor_transaction                 master_moniter_transaction_queue[$];  
xil_axi_uint                            master_moniter_transaction_queue_size =0;  
axi_monitor_transaction                 mst_scb_transaction;  
axi_monitor_transaction                 passthrough_monitor_transaction;  
axi_monitor_transaction                 passthrough_master_moniter_transaction_queue[$];  
xil_axi_uint                            passthrough_master_moniter_transaction_queue_size =0;  
axi_monitor_transaction                 passthrough_mst_scb_transaction;  
axi_monitor_transaction                 passthrough_slave_moniter_transaction_queue[$];  
xil_axi_uint                            passthrough_slave_moniter_transaction_queue_size =0;  
axi_monitor_transaction                 passthrough_slv_scb_transaction;  
axi_monitor_transaction                 slv_monitor_transaction;  
axi_monitor_transaction                 slave_moniter_transaction_queue[$];  
xil_axi_uint                            slave_moniter_transaction_queue_size =0;  
axi_monitor_transaction                 slv_scb_transaction;  
xil_axi_uint                           mst_agent_verbosity = 0;  
xil_axi_uint                           slv_agent_verbosity = 0;  
xil_axi_uint                           passthrough_agent_verbosity = 0;  
bit                                     clock;
bit                                     reset;
bit irq; 
xil_axi_ulong                           mem_rd_addr;
xil_axi_ulong                           mem_wr_addr;
bit[32-1:0]                             write_data;
bit                                     write_strb[];
bit[32-1:0]                             read_data;
ecpri_v2_0_bfm_1_slave_0_0_slv_mem_t          slv_agent_0;
bit error_0;
bit done_0;
bit init_0;
integer result_slave;  
bit [31:0] S00_AXI_test_data[3:0]; 
 localparam LC_AXI_BURST_LENGTH = 8; 
 localparam LC_AXI_DATA_WIDTH = 32; 
task automatic COMPARE_DATA; 
  input [(LC_AXI_BURST_LENGTH * LC_AXI_DATA_WIDTH)-1:0]expected; 
  input [(LC_AXI_BURST_LENGTH * LC_AXI_DATA_WIDTH)-1:0]actual; 
  begin 
    if (expected === 'hx || actual === 'hx) begin 
      $display("TESTBENCH ERROR! COMPARE_DATA cannot be performed with an expected or actual vector that is all 'x'!"); 
 result_slave = 0;    $stop; 
  end 
  if (actual != expected) begin 
    $display("TESTBENCH ERROR! Data expected is not equal to actual.",     " expected = 0x%h",expected,     " actual   = 0x%h",actual); 
    result_slave = 0; 
    $stop; 
  end 
  else  
    begin 
     $display("TESTBENCH Passed! Data expected is equal to actual.", 
              " expected = 0x%h",expected,               " actual   = 0x%h",actual); 
    end 
  end 
endtask 
integer                                 i; 
integer                                 j;  
xil_axi_uint                            trans_cnt_before_switch = 48;  
xil_axi_uint                            passthrough_cmd_switch_cnt = 0;  
event                                   passthrough_mastermode_start_event;  
event                                   passthrough_mastermode_end_event;  
event                                   passthrough_slavemode_end_event;  
xil_axi_uint                            mtestID;  
xil_axi_ulong                           mtestADDR;  
xil_axi_len_t                           mtestBurstLength;  
xil_axi_size_t                          mtestDataSize;   
xil_axi_burst_t                         mtestBurstType;   
xil_axi_lock_t                          mtestLOCK;  
xil_axi_cache_t                         mtestCacheType = 0;  
xil_axi_prot_t                          mtestProtectionType = 3'b000;  
xil_axi_region_t                        mtestRegion = 4'b000;  
xil_axi_qos_t                           mtestQOS = 4'b000;  
xil_axi_data_beat                       dbeat;  
xil_axi_data_beat [255:0]               mtestWUSER;   
xil_axi_data_beat                       mtestAWUSER = 'h0;  
xil_axi_data_beat                       mtestARUSER = 0;  
xil_axi_data_beat [255:0]               mtestRUSER;      
xil_axi_uint                            mtestBUSER = 0;  
xil_axi_resp_t                          mtestBresp;  
xil_axi_resp_t[255:0]                   mtestRresp;  
bit [63:0]                              mtestWDataL; 
bit [63:0]                              mtestRDataL; 
axi_transaction                         pss_wr_transaction;   
axi_transaction                         pss_rd_transaction;   
axi_transaction                         reactive_transaction;   
axi_transaction                         rd_payload_transaction;  
axi_transaction                         wr_rand;  
axi_transaction                         rd_rand;  
axi_transaction                         wr_reactive;  
axi_transaction                         rd_reactive;  
axi_transaction                         wr_reactive2;   
axi_transaction                         rd_reactive2;  
axi_ready_gen                           bready_gen;  
axi_ready_gen                           rready_gen;  
axi_ready_gen                           awready_gen;  
axi_ready_gen                           wready_gen;  
axi_ready_gen                           arready_gen;  
axi_ready_gen                           bready_gen2;  
axi_ready_gen                           rready_gen2;  
axi_ready_gen                           awready_gen2;  
axi_ready_gen                           wready_gen2;  
axi_ready_gen                           arready_gen2;  
xil_axi_payload_byte                    data_mem[xil_axi_ulong];  
bit [31:0] S_AXI_INTR_globalenData; 
bit [31:0] S_AXI_INTR_intrenData; 
bit [31:0] S_AXI_INTR_pendData; 
bit [31:0] S_AXI_INTR_ackData; 
bit [31:0] S_AXI_INTR_globalenAddress; 
bit [31:0] S_AXI_INTR_intrenAddress; 
bit [31:0] S_AXI_INTR_pendAddress; 
bit [31:0] S_AXI_INTR_ackAddress; 
bit [1:0] S_AXI_INTR_lite_response; 
bit [2:0] S_AXI_INTR_mtestProtection_lite; 
integer S_AXI_INTR_mtestdatasizelite; 
ecpri_v2_0_bfm_1_master_0_0_mst_t          mst_agent_0;

  `BD_WRAPPER DUT(
      .ARESETN(reset), 
.M00_AXI_INIT_AXI_TXN(init_0),
.M00_AXI_TXN_DONE(done_0),
.M00_AXI_ERROR(error_0),
        .irq (irq),  
      .ACLK(clock) 
    ); 
  
initial begin
    slv_agent_0 = new("slave vip agent",DUT.`BD_INST_NAME.slave_0.inst.IF);
    slv_agent_0.vif_proxy.set_dummy_drive_type(XIL_AXI_VIF_DRIVE_NONE);
    slv_agent_0.set_agent_tag("Slave VIP");
    slv_agent_0.set_verbosity(slv_agent_verbosity);
    slv_agent_0.start_slave();
     mst_agent_0 = new("master vip agent",DUT.`BD_INST_NAME.master_0.inst.IF);//ms  
   mst_agent_0.vif_proxy.set_dummy_drive_type(XIL_AXI_VIF_DRIVE_NONE); 
   mst_agent_0.set_agent_tag("Master VIP"); 
   mst_agent_0.set_verbosity(mst_agent_verbosity); 
   mst_agent_0.start_master(); 
     $timeformat (-12, 1, " ps", 1);
  end
  initial begin
    reset <= 1'b0;
    #200ns;
    reset <= 1'b1;
    repeat (5) @(negedge clock); 
  end
  always #5 clock <= ~clock;
  initial begin
      S_AXI_TEST ( );

    init_0 = 0;
    #200ns;
    init_0 =1'b1;
    #20ns;
    init_0 = 1'b0;
    $display("EXAMPLE TEST M00_AXI:");
      wait( done_0 == 1'b1);
      $display("M00_AXI: PTGEN_TEST_FINISHED!");
      if ( error_0 ) begin
        $display("PTGEN_TEST: FAILED!");
      end else begin
        $display("PTGEN_TEST: PASSED!");
      end
      #1ns;
      $finish;
  end
  initial begin
  #1;
    forever begin
      slv_agent_0.monitor.item_collected_port.get(slv_monitor_transaction);
      slave_moniter_transaction_queue.push_back(slv_monitor_transaction);
      slave_moniter_transaction_queue_size++;
    end
  end
task automatic S_AXI_TEST;  
begin   
#1; 
   S_AXI_INTR_TEST( ); 
  end 
endtask  
       task automatic S_AXI_INTR_TEST; 
         begin 
         $display("---------------------------------------------------------"); 
         $display("EXAMPLE TEST : S_AXI_INTR"); 
         $display("Simple Interrupt generation test"); 
         $display("---------------------------------------------------------"); 
                S_AXI_INTR_globalenAddress = `S_AXI_INTR_SLAVE_ADDRESS; 
                S_AXI_INTR_intrenAddress = `S_AXI_INTR_SLAVE_ADDRESS + 32'h00000004; 
                S_AXI_INTR_pendAddress = `S_AXI_INTR_SLAVE_ADDRESS + 32'h00000010; 
                S_AXI_INTR_ackAddress = `S_AXI_INTR_SLAVE_ADDRESS + 32'h0000000c; 
                S_AXI_INTR_globalenData = 32'h00000001;          
                S_AXI_INTR_intrenData = 32'h00000001;  
                S_AXI_INTR_ackData = 32'h00000001;    
                S_AXI_INTR_pendData = 32'h00000000;   
                S_AXI_INTR_mtestProtection_lite = 0;      
         mtestID = 0; 
         mtestADDR = S_AXI_INTR_globalenAddress; 
         mtestBurstLength = 0; 
         mtestDataSize = xil_axi_size_t'(xil_clog2(32/8)); 
         mtestBurstType = XIL_AXI_BURST_TYPE_INCR;  
         mtestLOCK = XIL_AXI_ALOCK_NOLOCK;  
         mtestCacheType = 0;  
         mtestProtectionType = 0;  
         mtestRegion = 0; 
         mtestQOS = 0; 
         mtestWDataL[31:0] = S_AXI_INTR_globalenData; 
         mst_agent_0.AXI4LITE_WRITE_BURST( 
            mtestADDR, 
            mtestProtectionType, 
            mtestWDataL, 
            mtestBresp 
          );   
          mtestID = 0; 
          mtestADDR = S_AXI_INTR_intrenAddress; 
          mtestBurstLength = 0; 
          mtestDataSize = xil_axi_size_t'(xil_clog2(32/8)); 
          mtestBurstType = XIL_AXI_BURST_TYPE_INCR;  
          mtestLOCK = XIL_AXI_ALOCK_NOLOCK;  
          mtestCacheType = 0;  
          mtestProtectionType = 0;  
          mtestRegion = 0; 
          mtestQOS = 0; 
          mtestWDataL[31:0] = S_AXI_INTR_intrenData; 
          mst_agent_0.AXI4LITE_WRITE_BURST( 
            mtestADDR, 
            mtestProtectionType, 
            mtestWDataL, 
            mtestBresp 
          );   
          wait(irq == `IRQ_ACTIVE_STATE) @(posedge clock); 
          mtestID = 0; 
          mtestADDR = S_AXI_INTR_pendAddress; 
          mtestBurstLength = 0; 
          mtestDataSize = xil_axi_size_t'(xil_clog2(32/8)); 
          mtestBurstType = XIL_AXI_BURST_TYPE_INCR;  
          mtestLOCK = XIL_AXI_ALOCK_NOLOCK;  
          mtestCacheType = 0;  
          mtestProtectionType = 0;  
          mtestRegion = 0; 
          mtestQOS = 0; 
          mst_agent_0.AXI4LITE_READ_BURST( 
            mtestADDR, 
            mtestProtectionType, 
            mtestRDataL, 
            mtestRresp 
          );             
          mtestID = 0; 
          mtestADDR = S_AXI_INTR_ackAddress; 
          mtestBurstLength = 0; 
          mtestDataSize = xil_axi_size_t'(xil_clog2(32/8)); 
          mtestBurstType = XIL_AXI_BURST_TYPE_INCR;  
          mtestLOCK = XIL_AXI_ALOCK_NOLOCK;  
          mtestCacheType = 0;  
          mtestProtectionType = 0;  
          mtestRegion = 0; 
          mtestQOS = 0; 
          mtestWDataL[31:0] = S_AXI_INTR_ackData; 
          mst_agent_0.AXI4LITE_WRITE_BURST( 
            mtestADDR, 
            mtestProtectionType, 
            mtestWDataL, 
            mtestBresp 
          );     
          mtestID = 0; 
          mtestADDR = S_AXI_INTR_pendAddress; 
          mtestBurstLength = 0; 
          mtestDataSize = xil_axi_size_t'(xil_clog2(32/8)); 
          mtestBurstType = XIL_AXI_BURST_TYPE_INCR;  
          mtestLOCK = XIL_AXI_ALOCK_NOLOCK;  
          mtestCacheType = 0;  
          mtestProtectionType = 0;  
          mtestRegion = 0; 
          mtestQOS = 0; 
          mst_agent_0.AXI4LITE_READ_BURST( 
            mtestADDR, 
            mtestProtectionType, 
            mtestRDataL, 
            mtestRresp 
          ); 
	         if ( mtestRDataL[0] != 1'b0) begin         
            $display("ERROR: Interrupt not cleared at bit0");          
            $display("PTGEN_TEST: FAILED!");                        
            $stop;                                               
          end  else begin                                        
            $display ("PASS: Interrupt test successful");        
            $display("PTGEN_TEST: PASSED!");                       
          end  
          $display("---------------------------------------------------------"); 
          $display("EXAMPLE TEST S_AXI_INTR: PTGEN_TEST_FINISHED!"); 
          $display("---------------------------------------------------------"); 
        end 
      endtask 


endmodule
