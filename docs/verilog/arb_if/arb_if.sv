//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2006 Chris Spear and Synopsys Inc.  All rights reserved
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
// Interface for arbiter example
//-----------------------------------------------------------------------------


interface arb_if(input bit clk); 
  logic [1:0] grant, request; 
  logic reset; 

  clocking cb @(posedge clk); 
    output request; 
    input grant; 
  endclocking

  modport TEST (clocking cb,
                output reset);

  modport DUT (input request, reset, clk,
               output grant);

  modport MONITOR (input request, grant, reset, clk);

endinterface
