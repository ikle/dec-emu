/*
 * MIPS I Core Module
 *
 * Copyright (c) 2021-2024 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

`ifndef CPU_MIPS_CORE_V
`define CPU_MIPS_CORE_V  1

/*
 * MIPS I Instruction Cache Module
 */
module mips_ic #(
	parameter START = 32'b0
) (
	input clock, reset,
	output reg [31:0] PC, input [31:0] op,	/* iface to code memory	*/
	output reg [31:0] RO, RN,		/* iface to ID/RF stage	*/
	input FV, input [31:0] FA		/* branch from EX	*/
);
	localparam NOP = 32'b0;

	wire [31:0] next = PC + 4;		/* next PC for op	*/

	always @(posedge clock) begin
		PC <= reset ? START : FV ? FA  : next;
		RO <= reset ? NOP   : FV ? NOP : op;
		RN <= next;
	end
endmodule

/*
 * MIPS I Register File Module
 */
module mips_rf (
	input clock, input [31:0] op,
	input [4:0] ET, input [31:0] ER,	/* EX  target and result */
	input [4:0] MT, input [31:0] MR,	/* MEM target and result */
	input [4:0] WT, input [31:0] WR,	/* WB  target and result */
	output [31:0] S, T
);
	wire [4:0] rs = op[25:21];
	wire [4:0] rt = op[20:16];

	reg [31:0] R[31];

	always @(posedge clock)
		R[WT] <= WR;

	wire [31:0] GS = (rs == 5'b0) ? 32'b0 : R[rs];
	wire [31:0] GT = (rt == 5'b0) ? 32'b0 : R[rt];

	assign S = (rs == ET) ? ER : (rs == MT) ? MR : GS;
	assign T = (rt == ET) ? ER : (rt == MT) ? MR : GT;
endmodule

/*
 * MIPS I Jumps Pipe
 */
module mips_pipe_jump (
	input clock, reset, input [31:0] op, next,
	input [31:0] S, T,				/* fetched vals	*/
	output reg [31:0] result,			/* link value	*/
	output reg [4:0] target,			/* save to	*/
	output reg branch,				/* do branch	*/
	output reg [31:0] address			/* br/mem addr	*/
);
	wire [5:0] C  = op[31:26];
	wire [4:0] rd = op[15:11];
	wire [5:0] F  = op[5:0];

	wire jr = !reset & C[5:0] == 6'b000000 & F[5:3] == 3'b001;
	wire ja = !reset & C[5:1] == 5'b00001;

	wire lr = jr & F[0];			/* jump reg and link	*/
	wire la = ja & C[0];			/* jump abs and link	*/

	always @(posedge clock) begin
		result  <= (lr | la) ? next : 32'b0;
		target  <= (lr ? rd : 0) | (la ? 31 : 0);
		branch  <= (jr | ja);
		address <= (jr ? S : 32'b0) | (ja ? {next[31:26], op[25:0]} : 32'b0);
	end

	/* EX stage is empty: just pass results from ID stage */
endmodule

/*
 * MIPS I Adder Pipe
 */
module mips_adder (
	input [2:0] F, input [31:0] S, T, output [31:0] R, output ov
);
	wire [33:0] s = {1'b0, S, F[1]} + {1'b0, F[1] ? ~T : T, F[1]};
	wire lt = F[0] ? s[33] : s[32];  /* carry vs sign */

	assign R  = F[2] ? {31'b0, lt} : s[32:1];  /* slt vs adder */
	assign ov = F[0] ? 0 : T[31] == S[31] && T[31] != R[31];
endmodule

module mips_pipe_adder (
	input clock, reset, input [31:0] op, next,
	input [31:0] S, T,				/* fetched vals	*/
	output [31:0] result,				/* ALU result	*/
	output reg [4:0] target,			/* save to	*/
	output [31:0] address				/* br/mem addr	*/
);
	wire [5:0] C  = op[31:26];
	wire [4:0] rt = op[20:16];
	wire [4:0] rd = op[15:11];
	wire [5:0] F  = op[5:0];

	wire add  = !reset & C[5:0] == 6'b000000 & F[5:2] == 4'b1000;
	wire regi = !reset & C[5:0] == 6'b000001;
	wire cond = !reset & C[5:2] == 4'b0001;
	wire addi = !reset & C[5:2] == 4'b0010;
	wire mem  = !reset & C[5:5] == 1'b1;

	wire BO = (regi | cond);
	wire AO = (add | BO | addi | mem);

	reg AV, MV; reg [2:0] AF; reg [31:0] AS, AT;

	wire [31:0] SI = {{16 {op[15]}}, op[15:0]};	/* sext (imm)	*/

	always @(posedge clock) begin
		{AV, MV} <= {add | addi, BO | mem};

		if (AO)  AF <= add ? {F[3], F[1:0]} : addi ? {C[1], C[1:0]} : 3'b001;
		if (AO)  AS <= BO ? next : S;
		if (AO)  AT <= add ? T : BO ? SI << 2 : SI;

		target <= (add ? rd : 0) | (addi ? rt : 0);
	end

	/* EX stage, do not use wires from ID stage! */

	wire [31:0] AR; mips_adder EX (AF, AS, AT, AR, );  // to do: overflow

	assign result  = (AV ? AR : 32'b0);
	assign address = (MV ? AR : 32'b0);
endmodule

/*
 * MIPS I Logic Pipe
 */
module mips_logic (
	input [2:0] F, input [31:0] S, T, output [31:0] R
);
	wire LU = F[2];  /* load upper */

	assign R = F[1] ? (F[0] ? LU ? T << 16 : ~(S | T) : S ^ T) :
			  (F[0] ? S | T : S & T);
endmodule

module mips_pipe_logic (
	input clock, reset, input [31:0] op, next,
	input [31:0] S, T,				/* fetched vals	*/
	output [31:0] result,				/* ALU result	*/
	output reg [4:0] target				/* save to	*/
);
	wire [5:0] C  = op[31:26];
	wire [4:0] rt = op[20:16];
	wire [4:0] rd = op[15:11];
	wire [5:0] F  = op[5:0];

	wire log  = !reset & C[5:0] == 6'b000000 & F[5:2] == 4'b1001;
	wire logi = !reset & C[5:2] == 4'b0011;

	wire LO = (log | logi);

	reg LV; reg [2:0] LF; reg [31:0] LS, LT;

	always @(posedge clock) begin
		LV <= LO;

		if (LO)  LF <= {logi, log ? F[1:0] : C[1:0]};
		if (LO)  LS <= S;
		if (LO)  LT <= log ? T : {16'b0, op[15:0]};

		target <= (log ? rd : 0) | (logi ? rt : 0);
	end

	/* EX stage, do not use wires from ID stage! */

	wire [31:0] LR; mips_logic EX (LF, LS, LT, LR);

	assign result = (LV ? LR : 32'b0);
endmodule

/*
 * MIPS I Shift Pipe
 */
module mips_shift (
	input [1:0] F, input [31:0] T, input [4:0] sa, output [31:0] R
);
	assign R = F[1] ? F[0] ? T >>> sa : T >> sa : T << sa;
endmodule

module mips_pipe_shift (
	input clock, reset, input [31:0] op, next,
	input [31:0] S, T,				/* fetched vals	*/
	output [31:0] result,				/* ALU result	*/
	output reg [4:0] target				/* save to	*/
);
	wire [5:0] C  = op[31:26];
	wire [4:0] rd = op[15:11];
	wire [4:0] sa = op[10:6];
	wire [5:0] F  = op[5:0];

	wire SO = !reset & C[5:0] == 6'b000000 & F[5:3] == 3'b000;

	reg SV; reg [1:0] SF; reg [31:0] ST; reg [4:0] SA;

	always @(posedge clock) begin
		SV <= SO;

		if (SO)  SF <= F[1:0];
		if (SO)  ST <= T;
		if (SO)  SA <= F[2] ? S[4:0] : sa;

		target <= (SO ? rd : 0);
	end

	/* EX stage, do not use wires from ID stage! */

	wire [31:0] SR; mips_shift EX (SF, ST, SA, SR);

	assign result = (SV ? SR : 32'b0);
endmodule

/*
 * MIPS I Branch Pipe
 */
module mips_cond (
	input [2:0] F, input [31:0] S, T, output R
);
	assign R = ((F[2] & (S == T)) | (F[1] & S[31])) ^ F[0];
endmodule

module mips_pipe_branch (
	input clock, reset, input [31:0] op, next,
	input [31:0] S, T,				/* fetched vals	*/
	output reg [31:0] link,				/* save link	*/
	output reg [4:0] target,			/* save to	*/
	output branch					/* do branch	*/
);
	wire [5:0] C  = op[31:26];
	wire [4:0] rt = op[20:16];
	wire [5:0] F  = op[5:0];

	wire regi = !reset & C[5:0] == 6'b000001;
	wire cond = !reset & C[5:2] == 4'b0001;

	wire BO = (regi | cond);
	wire bl = regi & rt[4];			/* branch and link	*/

	reg [2:0] BF; reg [31:0] BS, BT;

	always @(posedge clock) begin
		if (BO)  BF <= {C[2], C[2] == C[1], C[2] ? C[0] : rt[0]};	// eq, lt, inv
		if (BO)  BS <= S;
		if (BO)  BT <= T;

		link   <= bl ? next : 32'b0;
		target <= bl ? 31   : 0;
	end

	/* EX stage, do not use wires from ID stage! */

	mips_cond EX (BF, BS, BT, branch);
endmodule

/*
 * MIPS I Memory Pipe
 */
module mips_pipe_xfer (
	input clock, reset, input [31:0] op, next,
	input [31:0] S, T,				/* fetched vals	*/
	output reg [31:0] result,			/* link value	*/
	output reg [4:0] target,			/* save to	*/
	output reg [3:0] SM, LM,			/* wr/rd mask	*/
	output reg SE					/* sign-extend	*/
);
	wire [5:0] C  = op[31:26];
	wire [4:0] rt = op[20:16];
	wire [5:0] F  = op[5:0];

	wire LO = !reset & C[5:3] == 3'b100;		/* load op	*/
	wire SO = !reset & C[5:3] == 3'b101;		/* store op	*/

	always @(posedge clock) begin
		result  <= SO ? T : 32'b0;
		target  <= LO ? rt : 0;
		SM      <= SO ? C[1] ? 15 : C[0] ? 3 : 1 : 0;
		LM      <= LO ? C[1] ? 15 : C[0] ? 3 : 1 : 0;
		SE      <= !C[2];
	end

	/* EX stage is empty: just pass results from ID stage */
endmodule

/*
 * MIPS I Memory Load and Store Stage
 */
module mips_mem (
	input clock,
	input [31:0] EA, ER,			/* EX address & result	*/
	input [3:0] SM, LM,			/* EX store & load mask	*/
	input SE,				/* EX sign-extend	*/
	output [31:0] DA,			/* MEM data addr	*/
	output [3:0] we, output [31:0] DO,	/* MEM data out		*/
	output re, input [31:0] DI,		/* MEM data in		*/
	output [31:0] MR			/* MEM result		*/
);
	reg [31:0] MA, MD; reg [3:0] WE, RE; reg se;	/* MEM inputs	*/

	always @(posedge clock)
		{MA, MD, WE, RE, se} <= {EA, ER, SM, LM, SE};

	/* MEM stage, do not use wires from EX stage! */

	wire [1:0] sa = MA[1:0];

	assign DA = {MA[31:2], 2'b0};
	assign we = WE << sa;
	assign DO = MD << {sa, 3'b0};
	assign re = RE[0];

	wire [31:0] x = DI >> {sa, 3'b0};

	wire [7:0] a = RE[0] ? x[ 7: 0] : 0;
	wire [7:0] b = RE[1] ? x[15: 8] : {8 {a[7] & se}};
	wire [7:0] c = RE[2] ? x[23:16] : {8 {b[7] & se}};
	wire [7:0] d = RE[3] ? x[31:24] : {8 {b[7] & se}};

	assign MR = re ? {d, c, b, a} : MD;
endmodule

/*
 * MIPS I Core Module
 */
module mips_core (
	input clock, input reset,
	output reg [31:0] PC, input [31:0] op,		/* code bus	*/
	output [31:0] DA,				/* data addr	*/
	output [3:0] we, output [31:0] DO,		/* data out 	*/
	output re, input [31:0] DI			/* data in	*/
);
	wire [31:0] RO, RN;		/* ID/RF opcode and next PC	*/
	wire [31:0] EA;				/* EX branch address	*/
	wire EB;				/* EX branch signal	*/

	mips_ic IC (clock, reset, PC, op, RO, RN, EB, EA);

	wire [4:0] ET; wire [31:0] ER;		/* EX  target & result	*/
	reg  [4:0] MT; wire [31:0] MR;		/* MEM target & result	*/
	reg  [4:0] WT; reg  [31:0] WR;		/* WB  target & result	*/
	wire [31:0] S, T;			/* fetched values	*/

	mips_rf RF (clock, RO, ET, ER, MT, MR, WT, WR, S, T);

	wire [31:0] JR, AR, LR, SR, BR, XR;	/* pipe results		*/
	wire [4:0]  JT, AT, LT, ST, BT, XT;	/* pipe targets		*/
	wire        JV, BV;			/* pipe signals		*/
	wire [31:0] JA, AA;			/* pipe addresses	*/
	wire [3:0]  SM, LM; wire SE;		/* MEM function		*/

	mips_pipe_jump   PJ (clock, reset, RO, RN, S, T, JR, JT, JV, JA);
	mips_pipe_adder  PA (clock, reset, RO, RN, S, T, AR, AT, AA);
	mips_pipe_logic  PL (clock, reset, RO, RN, S, T, LR, LT);
	mips_pipe_shift  PS (clock, reset, RO, RN, S, T, SR, ST);
	mips_pipe_branch PB (clock, reset, RO, RN, S, T, BR, BT, BV);
	mips_pipe_xfer   PX (clock, reset, RO, RN, S, T, XR, XT, SM, LM, SE);

	assign ER = JR | AR | LR | SR | BR | XR;	/* EX result	*/
	assign ET = JT | AT | LT | ST | BT | XT;	/* EX target	*/
	assign EB = JV | BV;				/* EX branch	*/
	assign EA = JA | AA;				/* EX address	*/

	mips_mem MEM (clock, AA, ER, SM, LM, SE, DA, we, DO, re, DI, MR);

	always @(posedge clock)
		{MT, WT, WR} <= {ET, MT, MR};
endmodule

`endif  /* CPU_MIPS_CORE_V */
