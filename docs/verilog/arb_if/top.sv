//-----------------------------------------------------------------------------
// This confidential and proprietary software may be used only as authorized
// by a licensing agreement from Synopsys Inc. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2006 Chris Spear and Synopsys Inc.  All rights reserved
//
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------
// Top level module for arbiter example
//-----------------------------------------------------------------------------

`timescale 1ns/1ns

module top;
  bit  clk;
  always #5 clk = !clk; 

  arb_if arbif(clk); 
  arb a1 (arbif);
  test t1(arbif);

endmodule
