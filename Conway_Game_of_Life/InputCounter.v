`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:56:25 11/13/2017 
// Design Name: 
// Module Name:    ConwayInput
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ConwayInput(
    input A,
    input B,
    input C,
    input D,
    input E,
    input F,
    input G,
    input H,
	 input Self,
    output Q
    );

wire top4, top2, top1, bot4, bot2, bot1, Mux;
assign top4 = A&B&C&D;
assign bot4 = E&F&G&H;
assign top2 = A? (B? ~(C|D) : (C^D)) : (B? (C^D) : (C&D));
assign bot2 = E? (F? ~(G|H) : (G^H)) : (F? (G^H) : (G&H));
assign top1 = A^B^C^D;
assign bot1 = E^F^G^H;
assign Mux = top1? (bot1? (~(top2|bot2)&Self) : ((top2^bot2)&~Self)) : (bot1? ((top2^bot2)&~Self) : ((top2^bot2)&Self));
assign Q = Mux & ~top4 &~bot4;
endmodule
