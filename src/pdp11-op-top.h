/*
 * PDP-11 Instruction Simulator Top Module
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PDP11_OP_TOP_H
#define PDP11_OP_TOP_H  1

#include "pdp11-op-fc.h"
#include "pdp11-op-alu.h"

static inline int pdp_step_z8 (struct pdp *o, int op)
{
	const int fn = BITS (op, 3, 4);

	if (op <  64)  return pdp_sys (o, op);
	if (op < 128)  return pdp_jmp (o, op);

	switch (fn) {
	case 0:  return pdp_rts (o, op);			/* RTS */
	case 1:
	case 2:
	case 3:  return pdp_trap (o, 010);			/* SPL */
	case 4:
	case 5:  return pdp_clcc (o, op);			/* CLx */
	case 6:
	case 7:  return pdp_secc (o, op);			/* SEx */
	default: return pdp_swab (o, op);
	}
}

static inline int pdp_step_x3 (struct pdp *o, int op, int B)
{
	const int fn = BITS (op, 8, 4);

	switch (fn) {
	default:  return op < 256 ? pdp_step_z8 (o, op) : pdp_bcc (o, op, B);
	case  8:
	case  9:  return pdp_srv   (o, op, B);
	case 10:
	case 11:  return pdp_sop   (o, op, B);
	case 12:  return pdp_shift (o, op, B);
	case 13:				/* MARK, MFPI, MTPI, SXT */
	case 14:
	case 15:  return pdp_trap (o, 010);
	}
}

static inline int pdp_step (struct pdp *o, int op)
{
	const int B = (op < 0), fn = BITS (op, 12, 3);

	switch (fn) {
	case  0:  return pdp_step_x3 (o, op, B);
	case  7:  return pdp_trap (o, 010);			/* exts */
	default:  return pdp_dop (o, op, B);
	}
}

#endif  /* PDP11_OP_TOP_H */
