/*
 * MIPS I CPU Core
 *
 * Copyright (c) 2021-2024 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

`ifndef CPU_MIPS_I_V
`define CPU_MIPS_I_V  1

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

module mips_shift (
	input [6:0] F, input [31:0] S, T, input [4:0] sa, output [31:0] q
);
	wire [4:0] n = F[2] ? S[4:0] : sa;

	assign q = F[1] ? F[0] ? T >>> n : T >> n : T << n;
endmodule

module mips_ic (
	input clock, output [31:0] va, next
);
	reg [31:0] PC;

	always @(posedge clock)
		PC <= next;

	assign va   = PC;
	assign next = PC + 4;
endmodule

module mips_rf (
	input clock, input [31:0] op, RN, output reg [31:0] S, T, I, EN
);
	wire [4:0]  rs  = op[25:21];
	wire [4:0]  rt  = op[20:16];
	wire [15:0] imm = op[15:0];

	reg [31:0] GPR[31];

	always @(posedge clock) begin
		S  <= GPR[rs];
		T  <= GPR[rt];
		I  <= {{16 {imm[15]}}, imm};
		EN <= RN;
	end
endmodule

module mips_id (
	input clock, input [31:0] op,
	output reg [4:0] sa, output reg [6:0] func, output reg imm
);
	wire [5:0] C  = op[31:26];
	wire [4:0] SA = op[10:6];
	wire [5:0] F  = op[5:0];

	always @(posedge clock) begin
		sa   <= SA;
		func <= {C[3], C[5] ? 6'b100001 /* addu for VA */ :
			       C[3] ? {C[2:1] == 1, 2'b0, C[2:0]} : F};
		imm  <= C[5] | C[3];
	end
endmodule

module mips_ex (
	input clock,
	input [31:0] S, T, I, PC, input [4:0] sa, input [6:0] F, input i,
	output reg [31:0] D
);
	wire [31:0] AD, XD;
	wire ov;

	mips_alu   A (F, S, i ? I : T, AD, ov);
	mips_shift X (F, S, T, sa, XD);

	always @(posedge clock)
		D  <= F[5] ? AD : XD;
endmodule

module mips_core (
	input clock, output [31:0] PC, input [31:0] op
);
	wire [4:0] sa;
	wire [6:0] F;
	wire [31:0] S, T, I, D, RN, EN;
	wire i, ov;

	mips_ic IC (clock, PC, RN);
	mips_rf RF (clock, op, RN, S, T, I, EN);
	mips_id ID (clock, op, sa, F, i);
	mips_ex EX (clock, S, T, I, EN, sa, F, i, D);
endmodule

`endif  /* CPU_MIPS_I_V */
