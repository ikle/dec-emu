/*
 * MIPS I ALU
 *
 * Copyright (c) 2021-2024 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

`ifndef CPU_MIPS_ALU_V
`define CPU_MIPS_ALU_V  1

module mips_adder (
	input [6:0] F, input [31:0] S, T, output [31:0] q, output co, ov
);
	wire [33:0] s = {1'b0, S, F[1]} + {1'b0, F[1] ? ~T : T, F[1]};

	assign q  = s[32:1];
	assign co = s[33];
	assign ov = F[0] ? 0 : T[31] == S[31] && T[31] != q[31];
endmodule

module mips_logic (
	input [6:0] F, input [31:0] S, T, output [31:0] q
);
	wire LU = F[6];  /* load upper */

	assign q = F[1] ? (F[0] ? LU ? T << 16 : ~(S | T) : S ^ T) :
			  (F[0] ? S | T : S & T);
endmodule

module mips_alu (
	input [6:0] F, input [31:0] S, T, output [31:0] q, output ov
);
	wire [31:0] aq, lq, o;
	wire aco, aov, lt;

	mips_adder A (F, S, T, aq, aco, aov);
	mips_logic L (F, S, T, lq);

	assign lt = F[0] ? aco : aq[31];	/* carry vs sign	*/
	assign o  = F[2] ? lq  : aq;		/* logic vs adder	*/

	assign q  = F[3] ? {31'b0, lt} : o;	/* slt vs logic/adder	*/
	assign ov = F[3:2] == 0 && aov;		/* add/sub overflow	*/
endmodule

`endif  /* CPU_MIPS_ALU_V */
