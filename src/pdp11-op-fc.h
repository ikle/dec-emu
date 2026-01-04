/*
 * PDP-11 Flow Control Operations
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PDP11_OP_FC_H
#define PDP11_OP_FC_H  1

#include "pdp11-core.h"
#include "pdp11-ex.h"

static inline int pdp_trap (struct pdp *o, int vec)
{
	return	pdp_push (o, o->PS)				&&
		pdp_push (o, o->R[7])				&&
		pdp_read (o, vec, o->R + 7)			&&
		pdp_read (o, vec + 2, &o->PS);
}

static inline int pdp_rti (struct pdp *o)
{
	return	pdp_pop (o, o->R + 7)				&&
		pdp_pop (o, &o->PS);
}

static inline int pdp_sys (struct pdp *o, int op)
{
	switch (op) {
	case 0:  return 0;					/* HALT  */
	case 1:  return 0;					/* WAIT  */
	case 2:  return pdp_rti  (o);				/* RTI   */
	case 3:  return pdp_trap (o, 014);			/* BPT   */
	case 4:  return pdp_trap (o, 020);			/* IOT   */
	case 5:  return 0;					/* RESET */
	default: return pdp_trap (o, 010);
	}
}

static inline int pdp_jmp (struct pdp *o, int op)
{
	int y, D, A;

	return	pdp_pull (o, op, 2, &y, &D, &A)			&&
		D ? pdp_trap (o, 010) : pdp_wbg (o, 7, A);
}

static inline int pdp_rts (struct pdp *o, int op)
{
	const int x = BITS (op, 0, 3);

	return	pdp_wbg (o, 7, o->R[x])				&&
		pdp_pop (o, o->R + x);
}

static inline int pdp_bcc (struct pdp *o, int op, int B)
{
	const int A = o->R[7] + (int8_t) op * 2;

	return pdp_cond (o->PS, op, B) ? pdp_wbg (o, 7, A) : 1;
}

static inline int pdp_jsr (struct pdp *o, int op)
{
	int x = BITS (op, 6, 3), y, D, A;

	return	pdp_pull (o, op, 2, &y, &D, &A)			&&
		pdp_push (o, o->R[x])				&&
		pdp_wbg  (o, x, o->R[7])			&&
		D ? pdp_trap (o, 010) : pdp_wbg (o, 7, A);
}

static inline int pdp_srv (struct pdp *o, int op, int B)
{
	return B ? pdp_trap (o, BIT (op, 8) ? 034 : 030) : pdp_jsr (o, op);
}

#endif  /* PDP11_OP_FC_H */
