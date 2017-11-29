`timescale 1ns / 1ps

module ConwayVGA(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0, btnU, btnD,
	btnR, btnC, btnL, St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	input ClkPort;
	input	btnL, btnU, btnD, btnR, btnC;	
	input	Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, btnC);
	BUF BUF3 (start, Sw1);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;
	reg [63:0] RegArray [0:47];
	reg state;
	integer i, j;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] position;
	
	always @(posedge DIV_CLK[21])
		begin
			if(reset)
				position<=240;
			else if(btnD && ~btnU)
				position<=position+2;
			else if(btnU && ~btnD)
				position<=position-2;	
		end

	wire R = CounterY>=(position-10) && CounterY<=(position+10) && CounterX[8:5]==7;
	wire G = CounterX>100 && CounterX<200 && CounterY[5:3]==7;
	wire B = 0;
	
	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	always @ (posedge DIV_CLK[21], posedge reset)
	begin: Game
		reg top4, top2, top1, bot4, bot2, bot1, Mux, A, B, C, D, E, F, G, H;
		if(reset)
		begin
			state<=0;
			for(i = 0; i < 48; i = i + 1)
			begin
				for(j = 0; j < 64; j = j + 1)
				begin
					if((Sw0 && i > 36 && j > 32)||(Sw1 && i > 36 && j < 32)||(Sw2 && i < 36 && i > 24 && j > 32)||(Sw3 && i > 24 && i < 36 && j < 32)||
					(Sw4 && i > 12 && i < 23 && j > 32)||(Sw5 && i > 12 && i < 23 && j < 32)||(Sw6 && i < 12 && j > 32)||(Sw7 && i < 12 && j < 32))
						RegArray[i][j]<=1'b1;
					else
						RegArray[i][j]<=0;
				end
			end
		end
		else if(btnL)
			state<=1'b0;
		else if(btnR)
			state<=1'b1;
		else if(state==1'b1)
		begin
			for(i = 0; i < 48; i = i + 1)
			begin
				for(j = 0; j < 64; j = j + 1)
				begin
					A = (i==0 || j==0) ? 1'b0 : RegArray[i-1][j-1];
					B = (i==0) ? 1'b0 : RegArray[i-1][j];
					C = (i==0 || j==63) ? 1'b0 : RegArray[i-1][j+1];
					D = (j==63) ? 1'b0 : RegArray[i][j+1];
					E = (i==47 || j==63) ? 1'b0 : RegArray[i+1][j+1];
					F = (i==47) ? 1'b0 : RegArray[i+1][j];
					G = (i==47 || j==0) ? 1'b0 : RegArray[i+1][j-1];
					H = (i==0) ? 1'b0 : RegArray[i-1][j];
					top4 = A&B&C&D;
					bot4 = E&F&G&H;
					top2 = A? (B? ~(C|D) : (C^D)) : (B? (C^D) : (C&D));
					bot2 = E? (F? ~(G|H) : (G^H)) : (F? (G^H) : (G&H));
					top1 = A^B^C^D;
					bot1 = E^F^G^H;
					Mux = top1? (bot1? (~(top2|bot2)&RegArray[i][j]) : (top2^bot2)) : (bot1? (top2^bot2) : ((top2^bot2)&RegArray[i][j]));
					RegArray[i][j] <= Mux & ~top4 &~bot4;
					//RegArray[i][j]<=WireArray[i][j];
				end
			end
		end
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign {LD7, LD6, LD5, LD4} = {state, ~state, 1'b0, 1'b0};
	assign {LD3, LD2, LD1, LD0} = {btnL, btnU, btnR, btnD}; // Reset is driven by BtnC
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = {Sw7, Sw6, Sw5, Sw4};
	assign SSD2 = {Sw3, Sw2, Sw1, Sw0};
	assign SSD1 = {Sw7, Sw6, Sw5, Sw4};
	assign SSD0 = {Sw3, Sw2, Sw1, Sw0};
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule
