//////////////////////////////////////////////////////////////////////////////////
// Author:			Shideh Shahidi, Bilal Zafar, Gandhi Puvvada
// Create Date:		02/25/08
// File Name:		Conways_top.v 
// Description: 
//
//
// Revision: 		2.2
// Additional Comments: 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module Conways_top
		(MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS, // Disable the three memory chips

        ClkPort,                           // the 100 MHz incoming clock signal
		
		BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons BtnL, BtnR,
		BtnC,                              // the center button (this is our reset in most of our designs)
		Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0, // 8 switches
		Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 8 LEDs
		An3, An2, An1, An0,			       // 4 anodes
		Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
		Dp                                 // Dot Point Cathode on SSDs
	  );

	/*  INPUTS */
	// Clock & Reset I/O
	input		ClkPort;	
	// Project Specific Inputs
	input		BtnL, BtnU, BtnD, BtnR, BtnC;	
	input		Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0;
	
	
	/*  OUTPUTS */
	// Control signals on Memory chips 	(to disable them)
	output 	MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS;
	// Project Specific Outputs
	// LEDs
	output 	Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7;
	// SSD Outputs
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	An0, An1, An2, An3;	

	
	/*  LOCAL SIGNALS */
	wire		Reset, ClkPort;
	wire		board_clk, sys_clk;
	wire [1:0] 	ssdscan_clk;
	reg [26:0]	DIV_CLK;
	wire [0:8] WireArray [7:0];
	reg [0:8] RegArray [7:0];
	wire Start_Ack_Pulse;
	wire in_AB_Pulse, CEN_Pulse, BtnR_Pulse, BtnU_Pulse;
	wire q_I, q_Run;
	reg [7:0] Ain; 
	reg [7:0] Bin;
	reg [3:0]	SSD;
	wire [3:0]	SSD3, SSD2, SSD1, SSD0; 
	reg [7:0]  SSD_CATHODES; 
	reg state;
	integer i, j;
	assign {MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS} = 5'b11111;
	
	
//------------
// CLOCK DIVISION

	BUFGP BUFGP1 (board_clk, ClkPort); 	

	assign Reset = BtnC;

//-------------------	
	// In this design, we run the core design at full 50MHz clock!
	assign	sys_clk = board_clk;
	// assign	sys_clk = DIV_CLK[25];
always @(posedge board_clk, posedge Reset) 	
    begin							
        if (Reset)
		DIV_CLK <= 0;
        else
		DIV_CLK <= DIV_CLK + 1'b1;
    end
//------------
// INPUT: SWITCHES & BUTTONS
	// BtnL is used as both Start and Acknowledge. 
	// To make this possible, we need a single clock producing  circuit.
	
	for(i = 1; i < 479; i = i + 1)
			begin
				for(j = 1; j < 639; j = j + 1)
				begin
					ConwayInput(RegArray[i-1][j-1], RegArray[i-1][j], RegArray[i-1][j+1],
					RegArray[i][j-1], RegArray[i][j+1], RegArray[i+1][j], RegArray[i+1][j-1], RegArray[i+1][j+1],
					RegArray[i][j], WireArray[i][j]);
				end
			end
			
	for(i = 1; i < 479; i = i + 1)
			begin
				ConwayInput(1'b0, RegArray[i-1][0], RegArray[i-1][1],
					1'b0, RegArray[i][1], RegArray[i+1][0], 1'b0, RegArray[i+1][1],
					RegArray[i][0], WireArray[i][0]);
				ConwayInput(RegArray[i-1][638], RegArray[i-1][639], 1'b0,
					RegArray[i][638], 1'b0, RegArray[i+1][639], RegArray[i+1][638], 1'b0,
					RegArray[i][639], WireArray[i][639]);
			end
			
	for(j = 1; j < 639; j = j + 1)
			begin
				ConwayInput(1'b0, 1'b0, 1'b0,
					RegArray[0][j-1], RegArray[0][j+1], RegArray[1][j], RegArray[1][j-1], RegArray[1][j+1],
					RegArray[0][j], WireArray[i][j]);
				ConwayInput(RegArray[478][j-1], RegArray[478][j], RegArray[478][j+1],
					RegArray[479][j-1], RegArray[479][j+1], 1'b0, 1'b0, 1'b0,
					RegArray[479][j], WireArray[479][j]);
			end
			
	ConwayInput(1'b0, 1'b0, 1'b0,
					1'b0, RegArray[i][1], RegArray[1][j], 1'b0, RegArray[1][1],
					RegArray[0][0], WireArray[0][0]);
	ConwayInput(1'b0, 1'b0, 1'b0,
					RegArray[0][638], 1'b0, RegArray[1][639], RegArray[1][638], 1'b0,
					RegArray[0][639], WireArray[0][639]);
	ConwayInput(1'b0, RegArray[478][0], RegArray[438][1],
					1'b0, RegArray[479][1], 1'b0, 1'b0, 1'b0,
					RegArray[479][0], WireArray[479][0]);
	ConwayInput(RegArray[478][638], RegArray[478][639], 1'b0,
					RegArray[479][638], 1'b0, 1'b0, 1'b0, 1'b0,
					RegArray[479][639], WireArray[479][639]);
	
	
//------------
// DESIGN
	always @ (posedge sys_clk, posedge Reset)
	begin
		if(Reset)
		begin
			state<=0;
			for(i = 0; i < 480; i = i + 1)
			begin
				for(j = 0; j < 640; j = j + 1)
				begin
					RegArray[j][i]<=0;
				end
			end
		end
		else if(state==0)
			state<=state;
		else if(BtnR)
			state<=state^(1'b1);
		else if(state==1)
		begin
			RegArray<=WireArray;
		end
	end
//------------
// OUTPUT: LEDS
	
	assign {Ld7, Ld6, Ld5, Ld4} = {q_I, q_Sub, q_Mult, q_Done};
	assign {Ld3, Ld2, Ld1, Ld0} = {BtnL, BtnU, BtnR, BtnD}; // Reset is driven by BtnC
	// Here
	// BtnL = Start/Ack
	// BtnU = Single-Step
	// BtnR = in_A_in_B
	// BtnD = not used here
	
//------------
// SSD (Seven Segment Display)
	
	//SSDs show Ain and Bin in initial state, A and B in subtract state, and GCD and i_count in multiply and done states.
	// ****** TODO  in Part 2 ******
	// assign y = s ? i1 : i0;  // an example of a 2-to-1 mux coding
	// assign y = s1 ? (s0 ? i3: i2): (s0 ? i1: i0); // an example of a 4-to-1 mux coding
	assign SSD3 = Ain[7:4];
	assign SSD3 = Ain[3:0];
	assign SSD3 = Bin[7:4];
	assign SSD3 = Bin[3:0];
	assign ssdscan_clk = DIV_CLK[19:18];
	assign An3	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An2	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An1	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An0	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  2'b00: SSD = SSD3;	
				  2'b01: SSD = SSD2;  	
				  
				  2'b10: SSD = SSD1;
				  2'b11: SSD = SSD0;
		endcase 
	end
	
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) 
			4'b0000: SSD_CATHODES = 8'b00000011; // 0
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0010: SSD_CATHODES = 8'b00100101; // 2
			4'b0011: SSD_CATHODES = 8'b00001101; // 3
			4'b0100: SSD_CATHODES = 8'b10011001; // 4
			4'b0101: SSD_CATHODES = 8'b01001001; // 5
			4'b0110: SSD_CATHODES = 8'b01000001; // 6
			4'b0111: SSD_CATHODES = 8'b00011111; // 7
			4'b1000: SSD_CATHODES = 8'b00000001; // 8
			4'b1001: SSD_CATHODES = 8'b00001001; // 9
			4'b1010: SSD_CATHODES = 8'b00010001; // A
			4'b1011: SSD_CATHODES = 8'b11000001; // B
			4'b1100: SSD_CATHODES = 8'b01100011; // C
			4'b1101: SSD_CATHODES = 8'b10000101; // D
			4'b1110: SSD_CATHODES = 8'b01100001; // E
			4'b1111: SSD_CATHODES = 8'b01110001; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
endmodule

