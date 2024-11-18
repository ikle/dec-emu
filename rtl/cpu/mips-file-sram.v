/*
 * MIPS I SRAM-Based Register File
 *
 * Copyright (c) 2021-2024 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

`ifndef CPU_MIPS_FILE_SRAM_V
`define CPU_MIPS_FILE_SRAM_V  1

module mips_file (
	input clock,
	input [4:0] rd, input [3:0] we, input [31:0] D,
	input [4:0] rs, rt, output [31:0] S, T
);
	reg [7:0] S0[31], S1[31], S2[31], S3[31];
	reg [7:0] T0[31], T1[31], T2[31], T3[31];

	always @(posedge clock) begin
		if (we[0])  S0[rd] <= D[7:0];
		if (we[1])  S1[rd] <= D[15:8];
		if (we[2])  S2[rd] <= D[23:16];
		if (we[3])  S3[rd] <= D[31:24];

		if (we[0])  T0[rd] <= D[7:0];
		if (we[1])  T1[rd] <= D[15:8];
		if (we[2])  T2[rd] <= D[23:16];
		if (we[3])  T3[rd] <= D[31:24];
	end

	assign S = rs == 5'b0 ? 32'b0 : {S3[rs], S2[rs], S1[rs], S0[rs]};
	assign T = rt == 5'b0 ? 32'b0 : {T3[rt], T2[rt], T1[rt], T0[rt]};
endmodule

`endif  /* CPU_MIPS_FILE_SRAM_V */
