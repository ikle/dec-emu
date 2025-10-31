/*
 * MIPS I Core Module
 *
 * Copyright (c) 2021-2025 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

`ifndef CPU_MIPS_CORE_V
`define CPU_MIPS_CORE_V  1

/*
 * MIPS ALU Modules
 */
module mips_adder (
	input [2:0] F, input [31:0] S, T, output [31:0] R, output ov
);
	wire [33:0] s = {1'b0, S, F[1]} + {1'b0, T, F[1]};
	wire lt = F[0] ? s[33] : s[32];  /* carry vs sign */

	assign R  = F[2] ? {31'b0, lt} : s[32:1];  /* slt vs adder */
	assign ov = F[0] ? 0 : T[31] == S[31] && T[31] != R[31];
endmodule

module mips_logic (
	input [2:0] F, input [31:0] S, T, output [31:0] R
);
	wire LU = F[2];  /* load upper */

	assign R = F[1] ? (F[0] ? LU ? T << 16 : ~(S | T) : S ^ T) :
			  (F[0] ? S | T : S & T);
endmodule

module mips_shift (
	input [1:0] F, input [31:0] T, input [4:0] sa, output [31:0] R
);
	assign R = F[1] ? F[0] ? T >>> sa : T >> sa : T << sa;
endmodule

module mips_cond (
	input [2:0] F, input [31:0] S, T, output R
);
	assign R = ((F[2] & (S == T)) | (F[1] & S[31])) ^ F[0];
endmodule

/*
 * MIPS I Jump Pipe
 */
module mips_pipe_jump (
	input clock,
	input [31:0] op, PN, S,
	output reg [4:0] target, output reg [31:0] result, address,
	output reg branch
);
	/* RD0 - RD1 */

	wire [5:0] C  = op[31:26];
	wire [4:0] rd = op[15:11];
	wire [5:0] F  = op[5:0];

	wire jr = C[5:0] == 6'b000000 & F[5:3] == 3'b001;
	wire ja = C[5:1] == 5'b00001;

	wire lr = jr & F[0];			/* jump reg and link	*/
	wire la = ja & C[0];			/* jump abs and link	*/

	/* RD1 */

	reg [4:0] JT; reg [31:0] JR, JA; reg JB;

	always @(negedge clock) begin
		JT <= (lr ? rd : 0) | (la ? 31 : 0);
		JR <= (lr | la) ? PN : 0;
		JA <= (jr ? S : 0) | (ja ? {PN[31:26], op[25:0]} : 0);
		JB <= (jr | ja);
	end

	/* EX0 */

	always @(posedge clock) begin
		target  <= JT;			/* link register	*/
		result  <= JR;			/* link address		*/
		address <= JA;			/* jump address		*/
		branch  <= JB;			/* do branch flag	*/
	end
endmodule

/*
 * MIPS I Adder Pipe
 */
module mips_pipe_adder (
	input clock,
	input [31:0] op, PN, S, T,
	output reg [4:0] target, output reg [31:0] result, address
);
	/* RD0 - RD1 */

	wire [5:0] C  = op[31:26];
	wire [4:0] rt = op[20:16];
	wire [4:0] rd = op[15:11];
	wire [5:0] F  = op[5:0];

	wire add  = C[5:0] == 6'b000000 & F[5:2] == 4'b1000;
	wire regi = C[5:0] == 6'b000001;
	wire cond = C[5:2] == 4'b0001;
	wire addi = C[5:2] == 4'b0010;
	wire mem  = C[5:5] == 1'b1;

	wire BO = (regi | cond);			/* branch op	*/
	wire AO = (add | BO | addi | mem);		/* adder op	*/

	wire [31:0] SI = {{16 {op[15]}}, op[15:0]};	/* sext (imm)	*/
	wire [31:0] NY = add ? T : BO ? SI << 2 : SI;
	wire [2:0]  NF = add ? {F[3], F[1:0]} : addi ? {C[1], C[1:0]} : 3'b00;

	/* RD1 */

	reg [2:0] AF; reg [31:0] AX, AY; reg [4:0] AT; reg [31:0] AR, AA;
	reg AV, MV;

	always @(negedge clock) begin
		if (AO)  AF <= NF;
		if (AO)  AX <= BO ? PN : S;
		if (AO)  AY <= NF[1] ? ~NY : NY;

		AT <= (add ? rd : 0) | (addi ? rt : 0);
		{AV, MV} <= {add | addi, BO | mem};
	end

	/* EX0 */

	wire [31:0] AR; mips_adder EX (AF, AX, AY, AR, );  /* FRQ: check for overflow */

	always @(posedge clock) begin
		target  <= AT;			/* result register	*/
		result  <= AV ? AR : 0;		/* adder result		*/
		address <= MV ? AR : 0;		/* branch / mem address	*/
	end
endmodule

/*
 * MIPS I Logic Pipe
 */
module mips_pipe_logic (
	input clock,
	input [31:0] op, S, T,
	output reg [4:0] target, output reg [31:0] result
);
	/* RD0 - RD1 */

	wire [5:0] C  = op[31:26];
	wire [4:0] rt = op[20:16];
	wire [4:0] rd = op[15:11];
	wire [5:0] F  = op[5:0];

	wire log  = C[5:0] == 6'b000000 & F[5:2] == 4'b1001;
	wire logi = C[5:2] == 4'b0011;

	wire LO = (log | logi);				/* logic op	*/

	/* RD1 */

	reg [2:0] LF; reg [31:0] LX, LY; reg [4:0] LT; reg LV;

	always @(negedge clock) begin
		if (LO)  LF <= {logi, log ? F[1:0] : C[1:0]};
		if (LO)  LX <= S;
		if (LO)  LY <= log ? T : {16'b0, op[15:0]};

		LT <= (log ? rd : 0) | (logi ? rt : 0);
		LV <= LO;
	end

	/* EX0 */

	wire [31:0] LR; mips_logic EX (LF, LX, LY, LR);

	always @(posedge clock) begin
		target <= LT;			/* result register	*/
		result <= LV ? LR : 0;		/* logic result		*/
	end
endmodule

/*
 * MIPS I Shift Pipe
 */
module mips_pipe_shift (
	input clock,
	input [31:0] op, S, T,
	output reg [4:0] target, output reg [31:0] result
);
	/* RD0 - RD1 */

	wire [5:0] C  = op[31:26];
	wire [4:0] rd = op[15:11];
	wire [4:0] sa = op[10:6];
	wire [5:0] F  = op[5:0];

	wire SO = C[5:0] == 6'b000000 & F[5:3] == 3'b000;

	/* RD1 */

	reg [1:0] SF; reg [31:0] SX; reg [4:0] SY; reg [4:0] ST; reg SV;

	always @(negedge clock) begin
		if (SO)  SF <= F[1:0];
		if (SO)  SX <= T;
		if (SO)  SY <= F[2] ? S[4:0] : sa;

		ST <= (SO ? rd : 0);
		SV <= SO;
	end

	/* EX0 */

	wire [31:0] SR; mips_shift EX (SF, SX, SY, SR);

	always @(posedge clock) begin
		target <= ST;			/* result register	*/
		result <= SV ? SR : 0;		/* shift result		*/
	end
endmodule

/*
 * MIPS I Branch Pipe
 */
module mips_pipe_branch (
	input clock,
	input [31:0] op, PN, S, T,
	output reg [4:0] target, output reg [31:0] result,
	output reg branch
);
	/* RD0 - RD1 */

	wire [5:0] C  = op[31:26];
	wire [4:0] rt = op[20:16];
	wire [5:0] F  = op[5:0];

	wire regi = C[5:0] == 6'b000001;
	wire cond = C[5:2] == 4'b0001;

	wire BO = (regi | cond);			/* branch op	*/
	wire bl = regi & rt[4];				/* br. & link	*/

	/* RD1 */

	reg [2:0] BF; reg [31:0] BX, BY; reg [4:0] BT; reg [31:0] BR;

	always @(negedge clock) begin
		if (BO)  BF <= {C[2], C[2] == C[1], C[2] ? C[0] : rt[0]};	// eq, lt, inv
		if (BO)  BX <= S;
		if (BO)  BY <= T;

		BT <= bl ? 31 : 0;
		BR <= bl ? PN : 0;
	end

	/* EX0 */

	wire BB; mips_cond EX (BF, BX, BY, BB);

	always @(posedge clock) begin
		target  <= BT;			/* link register	*/
		result  <= BR;			/* link address		*/
		branch  <= BB;			/* do branch flag	*/
	end
endmodule

/*
 * MIPS I Memory Control Pipe
 */
module mips_pipe_xfer (
	input clock,
	input [31:0] op, S, T,
	output reg [4:0] target, output reg [31:0] result,
	output reg DCS, DWR
);
	/* RD0 - RD1 */

	wire [5:0] C  = op[31:26];
	wire [4:0] rt = op[20:16];

	wire mem = C[5];				/* mem op	*/
	wire LO  = C[5:3] == 3'b100;			/* load op	*/
	wire SO  = C[5:3] == 3'b101;			/* store op	*/

	wire [3:0] mask = (C[4] | C[1]) ? 15 : C[0] ? 3 : 1;

	/* RD1 */

	reg [4:0] XT; reg [31:0] XR; reg CS, WR; reg [3:0] BM; reg SE;

	always @(negedge clock) begin
		XT <= LO ? rt : 0;
		XR <= SO ? T  : 0;

		CS <= mem;
		WR <= mem ? C[3] : 0;
		BM <= mem ? mask : 0;
		SE <= LO ? C[2:1] == 2'b00 : SE;
	end

	/* EX0 */

	always @(posedge clock) begin
		target <= XT;			/* load register to	*/
		result <= XR;			/* store value		*/
	end

	/* EX1 */

	always @(negedge clock) begin
		DCS <= CS;
		DWR <= WR;
	end
endmodule

/*
 * MIPS Pipe
 *
 * VA, PA, PV -- virtual address, physical address and physical valid flag
 * CA, CD, CV -- code address, code data-out and code data valid flag
 */
module mips_pipe #(
	parameter START = 32'b0		/* direct-mapped start address	*/
)(
	input reset, clock,
	output [31:0] VA, input [31:0] PA, input PV,		/* TLB     */
	output reg [31:0] CA, input [31:0] CD, input CV,	/* i-cache */
	output [4:0] rs, rt, input [31:0] GS, GT,		/* GPR RD  */
	output DCS, output DWR,
	output reg [31:0] DA, DO, input [31:0] DI,		/* d-cache */
	output reg [4:0] rd, output reg [31:0] GD		/* GPR WR  */
);
	reg  [31:0] PC = START, op, s, t, MD;
	wire [31:0] JR, JA, AR, AA, LR, SR, BR, XR,  ER, MR = GD, BA;
	wire [4:0] JT, AT, LT, ST, BT, XT,  ET, MT = rd;
	wire JB, BB,  BV;

	assign VA = clock /* & CS */ ? AA : PC;  /* P0 for code, P1 for data */

	/* IF0 */

	wire [31:0] next = PC + 4;

	always @(posedge clock)
		CA <= reset ? START : PA;

	/* IF1 */

	always @(negedge clock) begin
		PC <= reset ? START : BV ? BA : next;
		op <= BV ? 0 : CD;	/* drop 2nd op after branch */
	end

	/* RD0 */

	assign rs = op[25:21];
	assign rt = op[20:16];

	always @(posedge clock) begin
		s <= GS;	/* P0 for read, P1 for write	*/
		t <= GT;
	end

	/* RD1 */

	wire [31:0] S = (rs == ET) ? ER : (rs == MT) ? MR : s;
	wire [31:0] T = (rt == ET) ? ER : (rt == MT) ? MR : t;

	/* RD0 - EX0 */

	mips_pipe_jump   MJ (clock, op, PC, S,    JT, JR, JA, JB);
	mips_pipe_adder  MA (clock, op, PC, S, T, AT, AR, AA    );
	mips_pipe_logic  ML (clock, op,     S, T, LT, LR        );
	mips_pipe_shift  MS (clock, op,     S, T, ST, SR        );
	mips_pipe_branch MB (clock, op, PC, S, T, BT, BR,     BB);
	mips_pipe_xfer   MX (clock, op,     S, T, XT, XR,         DCS, DWR);

	/* EX1 */

	assign ET = JT | AT | LT | ST | BT | XT;	/* EX target	*/
	assign ER = JR | AR | LR | SR | BR | XR;	/* EX result	*/
	assign BA = JA | AA;				/* EX address	*/
	assign BV = JB | BB;				/* EX branch	*/

	always @(negedge clock) begin
		DA <= PA;
		DO <= ER;
	end

	/* MEM0 */

	always @(posedge clock) begin
		MD <= DI;
		rd <= ET;
	end

	/* MEM1 */

	always @(negedge clock)
		GD <= DCS & !DWR ? MD : DO;
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

`endif  /* CPU_MIPS_CORE_V */
