/*
 * MIPS I Register File
 *
 * Copyright (c) 2021-2024 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

`ifndef CPU_MIPS_FILE_V
`define CPU_MIPS_FILE_V  1

module mips_file (
	input clock,
	input [4:0] rd, input [3:0] we, input [31:0] D,
	input [4:0] rs, rt, output [31:0] S, T
);
	reg [7:0] R0[31], R1[31], R2[31], R3[31];

	always @(posedge clock) begin
		if (we[0])  R0[rd] <= D[7:0];
		if (we[1])  R1[rd] <= D[15:8];
		if (we[2])  R2[rd] <= D[23:16];
		if (we[3])  R3[rd] <= D[31:24];
	end

	assign S = (rs == 5'b0) ? 32'b0 : {R3[rs], R2[rs], R1[rs], R0[rs]};
	assign T = (rt == 5'b0) ? 32'b0 : {R3[rt], R2[rt], R1[rt], R0[rt]};
endmodule

`endif  /* CPU_MIPS_FILE_V */
