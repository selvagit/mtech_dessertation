/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* XILINX CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
#include <stdio.h>
#include "mypixfull.h"
#include "xparameters.h"
#include "stdio.h"
#include "xil_io.h"
#include "xdmaps.h"

volatile static u8 SrcBuffer[64] __attribute__ ((aligned(64)));
volatile static u8 DestBuffer[64] __attribute__ ((aligned(64)));

// Dealing with DMA inside the PS
// Using ps7_dma_s (dmaps_v2_1) documentation. We use the file: xdmaps_example_w_intr.c as template

#define DMA_DEVICE_ID XPAR_XDMAPS_1_DEVICE_ID
#define DMA_LENGTH 1024 /* Length of the DMA Transfers */

/* Variable Definitions */
#ifdef __ICCARM__
#pragma data_alignment=32
static int Src[DMA_LENGTH];
static int Dst[DMA_LENGTH];
#pragma data_alignment=4
#else
static int Src[DMA_LENGTH] __attribute__ ((aligned (32)));
static int Dst[DMA_LENGTH] __attribute__ ((aligned (32)));
#endif

XDmaPs DmaInstance;

// Note: We place code sections in DDR memory
void set_DmaCmd (XDmaPs_Cmd *DmaCmd, int BurstSize, u32 *Source, u32 *Destination, u32 DMA_WORDS);

// Example for DMA Tutorial
// 4 Procedures:
// - Memory to Memory (channel 0)
// - Memory to Memory (channel 0)
// - Memory to AXI4-Full Peripheral (channel 1)
// - AXI4-Full Peripheral to Memory (channel 2)

int main()
{
	int i, Status, BurstSize;
	unsigned int Channel = 0;

	u32 baseaddr = XPAR_MYPIXFULL_0_S00_AXI_BASEADDR; // from xparameters.h
    u16 DeviceId = DMA_DEVICE_ID;

	//volatile int Checked[XDMAPS_CHANNELS_PER_DEV];
	XDmaPs_Config *DmaCfg;
	XDmaPs *DmaInst = &DmaInstance;
	XDmaPs_Cmd DmaCmd;

	BurstSize = 4;
	set_DmaCmd (&DmaCmd, BurstSize, (u32*) Src, (u32*) Dst, DMA_LENGTH); // (u32 *) Src: just indicates that Src is a pointer (which it is), but we need to type casting

	// Initialize the DMA Driver
	   DmaCfg = XDmaPs_LookupConfig(DeviceId); if (DmaCfg == NULL) { return XST_FAILURE;}
	   Status = XDmaPs_CfgInitialize(DmaInst, DmaCfg, DmaCfg->BaseAddress); if (Status != XST_SUCCESS) { return XST_FAILURE; }

	// FIRST transfer: memory to memory. Using Channel 0
	// *************************************************
	   xil_printf ("\n********************\nFIRST transfer: Memory to memory. Channel %d\n", Channel);
	   xil_printf ("\tSource Address: %08X\tDestination Address: %08X\n", Src, Dst);

	// Initialize Source, Clear Destination
	   for (i = 0; i < DMA_LENGTH; i++) { Src[i] = DMA_LENGTH - i; Dst[i] = 0; }

	// Initiates DMA command, specified in DmaCmd: Each time we do this (successfully), the XDmaPs_Cmd field in DmaInst (for the given channel)
    // will be filled up (DmaCmdToHw = Cmd), so that when XDmaPs_IsActive is run, the Channel will still be active (not idle, as we would like)
	   Status = XDmaPs_Start(DmaInst, Channel, &DmaCmd, 0); if (Status != XST_SUCCESS) { xil_printf ("DMA Error!\n"); return XST_FAILURE; }

	   // After XDmaPs_Start, we need to wait a bit before the operation is done. Interrupt are better to do this
	   xil_printf ("\t... This is a delay to let DMA finish. It is better to use Interrupts\n");
	   // TODO: Measure time using HW Timers and compare DMA with simple write/read on Peripheral

	// Results:
	   for (i = 0; i < DMA_LENGTH; i++)
		  if (i%2 == 0) xil_printf ("Dst[%d] = %d\t\t\t",i,Dst[i]);	else xil_printf ("Dst[%d] = %d\n",i,Dst[i]);

	// SECOND transfer: memory to memory. Re-using Channel 0
	// *****************************************************
	// In order to start another DMA Transfer on Channel 0, we must first make it IDLE.
	// Otherwise, it'll get stuck in the next XDmaPs_Start (ResetChannel does not work!)
  	   DmaInst->Chans[Channel].DmaCmdToHw = NULL; // Making Channel 0 idle!
	   xil_printf ("Is Channel %d idle? (idle=0 -> YES). idle = %d\n",Channel, XDmaPs_IsActive(DmaInst, Channel));

	   xil_printf ("\n********************\nSECOND transfer: Memory to memory. Channel %d\n", Channel);
	   xil_printf ("Source Address: %08X\t", Src); xil_printf ("Destination Address: %08X\n", Dst);

	// Initialize Source, Clear Destination
	   for (i = 0; i < DMA_LENGTH; i++) { Src[i] = i; Dst[i] = 0; }

	// Initiates DMA command, specified in DmaCmd
	   Status = XDmaPs_Start(DmaInst, Channel, &DmaCmd, 0); if (Status != XST_SUCCESS) { return XST_FAILURE; }
  	   xil_printf ("... This is a delay to let DMA finish... it is better to use Interrupts\n");

	// Results from SECOND TRANSFER:
	   for (i = 0; i < DMA_LENGTH; i++)
		   if (i%2 == 0) xil_printf ("Dst[%d] = %d\t\t",i,Dst[i]);	else xil_printf ("Dst[%d] = %d\n",i,Dst[i]);

	// THIRD transfer: memory to Pixel Processor. Using Channel 1
	// **********************************************************
	// Note: We do not need to do anything extra on the PL to do this.
	// There is a Peripheral Request Interface (3..0) to connect DMAC to the PL, only required when
	// the peripheral handles DMA by itself (not our case, we only have AXI4-Full capability)
	   xil_printf ("\nPixel Processor IP: Testing:\n");

	// This is just to show whether Current Channel (0) is idle now:
	   xil_printf ("Is Channel %d idle? (idle=0 is YES). idle = %d\n",Channel, XDmaPs_IsActive(DmaInst, Channel));

	// For Pixel Processor, we change the Channel. Writing into IP:
	   Channel = 1;
	   set_DmaCmd (&DmaCmd, BurstSize, (u32*) Src, (u32*) baseaddr, 4); // (u32 *) Src: just indicating that Src is a pointer (which it is), but we neeed to type casting

    // Initialize Source
	   Src[0] = 0xDEADBEEF; Src[1] = 0xBEBEDEAD; Src[2] = 0xFADEBEAD; Src[3] = 0xCAFEBEDF;

	   xil_printf ("\n********************\nTHIRD transfer: Memory to Pixel Processor. Channel %d\n", Channel);
	   xil_printf ("Source Address: %08X\t", Src);	xil_printf ("Destination Address: %08X\n", DmaCmd.BD.DstAddr);

    // Initiates DMA command, specified in DmaCmd. We write on IP
	   Status = XDmaPs_Start(DmaInst, Channel, &DmaCmd, 0); if (Status != XST_SUCCESS) { xil_printf ("Error!\n"); return XST_FAILURE; }
	   xil_printf ("... This is a delay to let DMA finish... it is better to use Interrupts\n");

	// FOURTH transfer: Pixel Processor to memory. Using Channel 2
	// ***********************************************************
	   Channel = 2;
	   set_DmaCmd (&DmaCmd, BurstSize, (u32*) baseaddr, (u32*) Dst, 4); // (u32 *) Src: just indicating that Src is a pointer (which it is), but we neeed to type casting

	// Clear destination
	   for (i = 0; i < 4; i++) Dst[i] = 0;

	   xil_printf ("\n********************\nFOURTH transfer: Pixel Processor to Memory. Channel %d\n", Channel);
	   xil_printf ("Source Address: %08X\t", DmaCmd.BD.SrcAddr); xil_printf ("Destination Address: %08X\n", DmaCmd.BD.DstAddr);

    // Initiates DMA command, specified in DmaCmd
	   Status = XDmaPs_Start(DmaInst, Channel, &DmaCmd, 0); if (Status != XST_SUCCESS) { xil_printf ("Error!\n"); return XST_FAILURE; }

	   xil_printf ("... This is a delay to let DMA finish... it is better to use Interrupts\n");

	// Printing results
	   for (i = 0; i < 4; i++) xil_printf ("Dst[%d] = %08x\n",i,Dst[i]);

    // Disabling caches
	// Xil_DCacheDisable(); Xil_ICacheDisable();
    return 0;
}

void set_DmaCmd (XDmaPs_Cmd *DmaCmd, int BurstSize, u32 *Source, u32 *Destination, u32 DMA_WORDS)
{
	// IMPORTANT: If we do not do clear DmaCmd (on any channel), pixel Processor doesn't work (we get the same data!)
	//            If we do it only on Channel 1 or 2, the output is just zeros.
	//            XDmaPs_Start does:
	//              - Cmd->DmaStatus = XST_FAILURE; --> not really important
	//              - Inside XDmaPs_GenDmaProg, we do: Cmd->GeneratedDmaProg = Buf;
	//                This provides a pointer into a DmaCmd field for a particular DMA program.
	//                 If we change ChanCtrl parameters, we need to generate a new DMA Program.
	//                 Otherwise, XDmaPs_Start will just use the previously stored DMA program
	//             So, if we want to reuse the variable 'DmaCmd' but with different ChanCtrl parameters,
	//              we have to clear it so that XDmaPs_Start   generates a new DMA program in Cmd
	//              This was not a problem for the FIRST and SECOND transfer, as the DMA program (and the parameters) was the same.

	memset(DmaCmd, 0, sizeof(XDmaPs_Cmd)); // Clearing DmaCmd: explicitly resets all fields of the DMA command!

	// Setting up Dma parameters for a certain Channel
	DmaCmd->ChanCtrl.SrcBurstSize = BurstSize;
	DmaCmd->ChanCtrl.SrcBurstLen = 4;
	DmaCmd->ChanCtrl.SrcInc = 1;
	DmaCmd->ChanCtrl.DstBurstSize = BurstSize;
	DmaCmd->ChanCtrl.DstBurstLen = 4;
	DmaCmd->ChanCtrl.DstInc = 1;
	DmaCmd->BD.SrcAddr = (u32) Source;
	DmaCmd->BD.DstAddr = (u32) Destination;
	DmaCmd->BD.Length = DMA_WORDS * sizeof(int); // Length of data transmission
}
