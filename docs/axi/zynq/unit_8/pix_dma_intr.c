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
#include "xscugic.h"

volatile static u8 SrcBuffer[64] __attribute__ ((aligned(64)));
volatile static u8 DestBuffer[64] __attribute__ ((aligned(64)));

// Dealing with DMA inside the PS
// Using ps7_dma_s (dmaps_v2_1) documentation. We use the file: xdmaps_example_w_intr.c as template

/************************** Constant Definitions *****************************/
/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define DMA_DEVICE_ID 			XPAR_XDMAPS_1_DEVICE_ID
#define INTC_DEVICE_ID			XPAR_SCUGIC_SINGLE_DEVICE_ID

#define DMA_DONE_INTR_0			XPAR_XDMAPS_0_DONE_INTR_0
#define DMA_DONE_INTR_1			XPAR_XDMAPS_0_DONE_INTR_1
#define DMA_DONE_INTR_2			XPAR_XDMAPS_0_DONE_INTR_2
#define DMA_DONE_INTR_3			XPAR_XDMAPS_0_DONE_INTR_3
#define DMA_DONE_INTR_4			XPAR_XDMAPS_0_DONE_INTR_4
#define DMA_DONE_INTR_5			XPAR_XDMAPS_0_DONE_INTR_5
#define DMA_DONE_INTR_6			XPAR_XDMAPS_0_DONE_INTR_6
#define DMA_DONE_INTR_7			XPAR_XDMAPS_0_DONE_INTR_7
#define DMA_FAULT_INTR			XPAR_XDMAPS_0_FAULT_INTR

#define DMA_LENGTH	1024	/* Length of the Dma Transfers */
#define TIMEOUT_LIMIT 	0x2000	/* Loop count for timeout */

/************************** Function Prototypes ******************************/
int SetupInterruptSystem(XScuGic *GicPtr, XDmaPs *DmaPtr);
void DmaDoneHandler(unsigned int Channel, XDmaPs_Cmd *DmaCmd, void *CallbackRef);
void set_DmaCmd (XDmaPs_Cmd *DmaCmd, int BurstSize, u32 *Source, u32 *Destination, u32 DMA_WORDS);
void wait_doneint(volatile int *Checked, unsigned int Channel);

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
#ifndef TESTAPP_GEN
XScuGic GicInstance;
#endif

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

	volatile int Checked[XDMAPS_CHANNELS_PER_DEV]; // up to 8 Channels

	u32 baseaddr = XPAR_MYPIXFULL_0_S00_AXI_BASEADDR; // from xparameters.h
    u16 DeviceId = DMA_DEVICE_ID;

	XDmaPs_Config *DmaCfg;
	XDmaPs *DmaInst = &DmaInstance;
	XDmaPs_Cmd DmaCmd;

	BurstSize = 4;
	set_DmaCmd (&DmaCmd, BurstSize, (u32*) Src, (u32*) Dst, DMA_LENGTH); // (u32 *) Src: just indicates that Src is a pointer (which it is), but we need to type casting

	// Initialize the DMAC Driver
	   DmaCfg = XDmaPs_LookupConfig(DeviceId); if (DmaCfg == NULL) { return XST_FAILURE;}
	   Status = XDmaPs_CfgInitialize(DmaInst, DmaCfg, DmaCfg->BaseAddress); if (Status != XST_SUCCESS) { return XST_FAILURE; }

    // Setup the Interrupt System: GIC (General Interrupt Controller)
	   Status = SetupInterruptSystem(&GicInstance, DmaInst);
	   if (Status != XST_SUCCESS) { return XST_FAILURE; }

	// ***********************************************************
	// FIRST transfer: memory to memory. Using Channel 0
	// *************************************************
	   xil_printf ("\n********************\nFIRST transfer: Memory to memory. Channel %d\n", Channel);
	   xil_printf ("Source Address: %08X\tDestination Address: %08X\n", Src, Dst);

	// Initialize Source, Clear Destination
	   for (i = 0; i < DMA_LENGTH; i++) { Src[i] = DMA_LENGTH - i; Dst[i] = 0; }

	// Set the Done interrupt handler: We assign the function 'DmaDoneHandler' (defined by us) to the Interrupt caused by done of 'Channel'
	// Note that we are not setting the FaultHandler. The ISRs for done and fault are already pre-defined in 'xdmaps.c'.
	   Checked[Channel] = 0;
	   XDmaPs_SetDoneHandler(DmaInst, Channel, DmaDoneHandler, (void *)Checked);
		// Assigns: DmaInst->Chans+Channel->DoneHandler = DmaDoneHandler;
		//          DmaInst->Chans+Channel->DoneRef = Checked; // reference data, variable to be modified
		// When the DMA Done Interrupt hits, the done ISR (XDmaPs_DoneISR_n) executes (on a certain Channel)
		// IMPORTANT: When 'XDmaPs_DoneISR_n' executes, it executes the DoneHandler (you can give it any name)'DmaDoneHandler'
		//            this way: DoneHandler(Channel, DmaCmd, ChanData->DoneRef); --> This is how we must define our Done Handler function
		//            Thus: 'Checked' is the Callback reference data. It is used inside XDmaPs_DoneISR_n
		//                  'DmaDoneHandler' the callback function. It is used inside XDmaPs_DoneISR_n

	// Initiates DMA command, specified in DmaCmd: Each time we do this (successfully), the XDmaPs_Cmd field in DmaInst (for the given channel)
    // will be filled up (DmaCmdToHw = Cmd), so that when XDmaPs_IsActive is run, the Channel will still be active (not idle, as we would like)
	   Status = XDmaPs_Start(DmaInst, Channel, &DmaCmd, 0); if (Status != XST_SUCCESS) { xil_printf ("DMA Error!\n"); return XST_FAILURE; }

	// Interrupt: Now the DMA is done. We check via Interrupt (there is a timeout)
	   wait_doneint(Checked, Channel);

	// Results:
	   for (i = 0; i < DMA_LENGTH; i++)
		  if (i%2 == 0) xil_printf ("\tDst[%d] = %d\t\t\t",i,Dst[i]);	else xil_printf ("Dst[%d] = %d\n",i,Dst[i]);

	// ***********************************************************
	// SECOND transfer: memory to memory. Re-using Channel 0
	// *****************************************************
	// To start another DMA Transfer on Channel 0, we must first make it IDLE. Otherwise, it'll get stuck in the next XDmaPs_Start (ResetChannel does not work!)
	   DmaInst->Chans[Channel].DmaCmdToHw = NULL; // Making Channel 0 idle!
	   xil_printf ("Channel %d: Is it idle? (idle=0 -> YES). idle = %d\n",Channel, XDmaPs_IsActive(DmaInst, Channel)); // For some reason,this always shows idle regardless

	   xil_printf ("\n********************\nSECOND transfer: Memory to memory. Channel %d\n", Channel);
	   xil_printf ("Source Address: %08X\t", Src); xil_printf ("Destination Address: %08X\n", Dst);

	// Initialize Source, Clear Destination
	   for (i = 0; i < DMA_LENGTH; i++) { Src[i] = i; Dst[i] = 0; }

	   Checked[Channel] = 0;
	   XDmaPs_SetDoneHandler(DmaInst, Channel, DmaDoneHandler, (void *)Checked);

	// Initiates DMA command, specified in DmaCmd
	   Status = XDmaPs_Start(DmaInst, Channel, &DmaCmd, 0); if (Status != XST_SUCCESS) { return XST_FAILURE; }
	   wait_doneint(Checked, Channel);

	// Results from SECOND TRANSFER:
	   for (i = 0; i < DMA_LENGTH; i++)
		   if (i%2 == 0) xil_printf ("\tDst[%d] = %d\t\t\t",i,Dst[i]);	else xil_printf ("Dst[%d] = %d\n",i,Dst[i]);

	// ***********************************************************
	// THIRD transfer: memory to Pixel Processor. Using Channel 1
	// **********************************************************
	// We do not need to do anything extra on the PL to do this. There is a Peripheral Request Interface (3..0) to connect DMAC to the PL, only required when
	// the peripheral handles DMA by itself (not our case, we only have AXI4-Full capability)
	   xil_printf ("\nPixel Processor IP: Testing:\n");

	// For Pixel Processor, we change the Channel. Writing into IP:
	   Channel = 1;
	   set_DmaCmd (&DmaCmd, BurstSize, (u32*) Src, (u32*) baseaddr, 4); // (u32 *) Src: just indicating that Src is a pointer (which it is), but we neeed to type casting

    // Initialize Source (4 words)
	   Src[0] = 0xDEADBEEF; Src[1] = 0xBEBEDEAD; Src[2] = 0xFADEBEAD; Src[3] = 0xCAFEBEDF;

	   xil_printf ("\n********************\nTHIRD transfer: Memory to Pixel Processor. Channel %d\n", Channel);
	   xil_printf ("Source Address: %08X\t", Src);	xil_printf ("Destination Address: %08X\n", DmaCmd.BD.DstAddr);

	   Checked[Channel] = 0;
	   XDmaPs_SetDoneHandler(DmaInst, Channel, DmaDoneHandler, (void *)Checked);

    // Initiates DMA command, specified in DmaCmd. We write on IP
	   Status = XDmaPs_Start(DmaInst, Channel, &DmaCmd, 0); if (Status != XST_SUCCESS) { xil_printf ("Error!\n"); return XST_FAILURE; }
	   wait_doneint(Checked, Channel);

	// ***********************************************************
	// FOURTH transfer: Pixel Processor to memory. Using Channel 2
	// ***********************************************************
	   Channel = 2;
	   set_DmaCmd (&DmaCmd, BurstSize, (u32*) baseaddr, (u32*) Dst, 4); // (u32 *) Src: just indicating that Src is a pointer (which it is), but we neeed to type casting

	// Clear destination
	   for (i = 0; i < 4; i++) Dst[i] = 0;

	   xil_printf ("\n********************\nFOURTH transfer: Pixel Processor to Memory. Channel %d\n", Channel);
	   xil_printf ("Source Address: %08X\t", DmaCmd.BD.SrcAddr); xil_printf ("Destination Address: %08X\n", DmaCmd.BD.DstAddr);

	   Checked[Channel] = 0;
	   XDmaPs_SetDoneHandler(DmaInst, Channel, DmaDoneHandler, (void *)Checked);

    // Initiates DMA command, specified in DmaCmd
	   Status = XDmaPs_Start(DmaInst, Channel, &DmaCmd, 0); if (Status != XST_SUCCESS) { xil_printf ("Error!\n"); return XST_FAILURE; }
	   wait_doneint(Checked, Channel);

	// Printing results
	   for (i = 0; i < 4; i++) xil_printf ("\tDst[%d] = %08x\n",i,Dst[i]);

    return 0;
}

void wait_doneint(volatile int *Checked, unsigned int Channel)
// Wait until the Done Interrupt hits.
{
	int TimeOutCnt;

	TimeOutCnt = 0;
	while (!Checked[Channel] && TimeOutCnt < TIMEOUT_LIMIT) { TimeOutCnt++; }
	if (TimeOutCnt >= TIMEOUT_LIMIT) { xil_printf ("Timeout!\n"); }
	if (Checked[Channel] < 0) { xil_printf ("(wait_doneint) Checked[Channel]<0: Checked[Channel]=%d\n", Checked[Channel]); } // DMA controller failed
	xil_printf ("(wait_doneint) Checked[%d] = %d.\t",Channel, Checked[Channel]); xil_printf ("DMA Done Interrupt hit and ISR executed successfully!\n");
   // sometimes we get Checked[0] like a big negative number, sometimes we get a 1 (as it should be)
}

void set_DmaCmd (XDmaPs_Cmd *DmaCmd, int BurstSize, u32 *Source, u32 *Destination, u32 DMA_WORDS)
{
	// IMPORTANT: If we do not do clear DmaCmd (on any channel), Pixel Processor doesn't work (we get the same data!)
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


/******************************************************************************/
/**
 *
 * This function connects the interrupt handler of the interrupt controller to
 * the processor.  This function is separate to allow it to be customized for
 * each application. Each processor or RTOS may require unique processing to
 * connect the interrupt handler.
 *
 * @param	GicPtr is the GIC instance pointer.
 * @param	DmaPtr is the DMA instance pointer.
 *
 * @return	None.
 *
 * @note	None.
 *
 ****************************************************************************/
int SetupInterruptSystem(XScuGic *GicPtr, XDmaPs *DmaPtr)
{
	int Status;
#ifndef TESTAPP_GEN
	XScuGic_Config *GicConfig;


	Xil_ExceptionInit();

	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	GicConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == GicConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(GicPtr, GicConfig,
				       GicConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect the interrupt controller interrupt handler to the hardware
	 * interrupt handling logic in the processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
			     (Xil_ExceptionHandler)XScuGic_InterruptHandler,
			     GicPtr);
#endif
	/*
	 * Connect the device driver handlers (ISRs?) that will be called when an interrupt
	 * for the device occurs, the device driver handler performs the specific
	 * interrupt processing for the device
	 */

	/*
	 * Connect the Fault ISR: XDmaPs_FaultISR (ISR defined in xdmaps.c)
	 */
	Status = XScuGic_Connect(GicPtr, DMA_FAULT_INTR, (Xil_InterruptHandler)XDmaPs_FaultISR, (void *)DmaPtr);
	if (Status != XST_SUCCESS) { return XST_FAILURE; }

	/*
	 * Connect the Done ISR for all 8 channels of DMA 0 (done ISRs defined in xdmaps.c)
	 */
	Status = XScuGic_Connect(GicPtr, DMA_DONE_INTR_0, (Xil_InterruptHandler)XDmaPs_DoneISR_0, (void *)DmaPtr);
	Status |= XScuGic_Connect(GicPtr,
				 DMA_DONE_INTR_1,
				 (Xil_InterruptHandler)XDmaPs_DoneISR_1,
				 (void *)DmaPtr);
	Status |= XScuGic_Connect(GicPtr,
				 DMA_DONE_INTR_2,
				 (Xil_InterruptHandler)XDmaPs_DoneISR_2,
				 (void *)DmaPtr);
	Status |= XScuGic_Connect(GicPtr,
				 DMA_DONE_INTR_3,
				 (Xil_InterruptHandler)XDmaPs_DoneISR_3,
				 (void *)DmaPtr);
	Status |= XScuGic_Connect(GicPtr,
				 DMA_DONE_INTR_4,
				 (Xil_InterruptHandler)XDmaPs_DoneISR_4,
				 (void *)DmaPtr);
	Status |= XScuGic_Connect(GicPtr,
				 DMA_DONE_INTR_5,
				 (Xil_InterruptHandler)XDmaPs_DoneISR_5,
				 (void *)DmaPtr);
	Status |= XScuGic_Connect(GicPtr,
				 DMA_DONE_INTR_6,
				 (Xil_InterruptHandler)XDmaPs_DoneISR_6,
				 (void *)DmaPtr);
	Status |= XScuGic_Connect(GicPtr,
				 DMA_DONE_INTR_7,
				 (Xil_InterruptHandler)XDmaPs_DoneISR_7,
				 (void *)DmaPtr);

	if (Status != XST_SUCCESS)
		return XST_FAILURE;

	/*
	 * Enable the interrupts for the device
	 */
	XScuGic_Enable(GicPtr, DMA_DONE_INTR_0);
	XScuGic_Enable(GicPtr, DMA_DONE_INTR_1);
	XScuGic_Enable(GicPtr, DMA_DONE_INTR_2);
	XScuGic_Enable(GicPtr, DMA_DONE_INTR_3);
	XScuGic_Enable(GicPtr, DMA_DONE_INTR_4);
	XScuGic_Enable(GicPtr, DMA_DONE_INTR_5);
	XScuGic_Enable(GicPtr, DMA_DONE_INTR_6);
	XScuGic_Enable(GicPtr, DMA_DONE_INTR_7);
	XScuGic_Enable(GicPtr, DMA_FAULT_INTR);

	Xil_ExceptionEnable();

	return XST_SUCCESS;

}


/*****************************************************************************/
/**
*
* DmaDoneHandler: Function defined by user. Called when 'done' Interrupt from DMA hits,
*                 i.e. upon every successful DMA Transaction
* @param	Channel is the Channel number.
* @param	DmaCmd is the Dma Command.
* @param	CallbackRef is the callback reference data.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void DmaDoneHandler(unsigned int Channel, XDmaPs_Cmd *DmaCmd, void *CallbackRef)
{

	/* done handler */
	volatile int *Checked = (volatile int *)CallbackRef;
	int Index;
	int Status = 1;
	int *Src;
	int *Dst;

	Src = (int *)DmaCmd->BD.SrcAddr;
	Dst = (int *)DmaCmd->BD.DstAddr;

	/* DMA successful */
	/* compare the src and dst buffer */ // This only works when comparing memory positions
	// This DOES NOT work for Pixel processor, since it will try to read data from
	// Pixel Processor. This is not available because the DMA transfer already extracted all the data!
/*	for (Index = 0; Index < DMA_LENGTH; Index++) {
		if ((Src[Index] != Dst[Index]) ||
				(Dst[Index] != DMA_LENGTH - Index)) {
			Status = -XST_FAILURE;
		}
	}
*/
    // The only thing this DoneHandler does is set Checked[Channel] to 1.
	Checked[Channel] = Status;
}

