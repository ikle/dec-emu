/*
 * PDP-11 Flow Control Operations
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PDP11_OP_FC_H
#define PDP11_OP_FC_H  1

static inline int pdp_trap (struct pdp *o, int vec)
{
	return	pdp_push (o, o->PS)		&&
		pdp_push (o, o->R[7])		&&
		pdp_read (o, vec, o->R + 7)	&&
		pdp_read (o, vec + 2, &o->PS);
}

static inline int pdp_rti (struct pdp *o)
{
	return	pdp_pop (o, o->R + 7)	&&
		pdp_pop (o, &o->PS);
}

static inline int pdp_sys (struct pdp *o, int op)
{
	switch (op) {
	case 2:  return pdp_rti  (o);				/* RTI */
	case 3:  return pdp_trap (o, 014);			/* BPT */
	case 4:  return pdp_trap (o, 020);			/* IOT */
	default: return 0;
	}
}

static inline int pdp_jmp (struct pdp *o, int op)
{
	int D, WD, WA;

	pdp_pull_c (o, op, 2, &D, &WD, &WA);

	return WD ? pdp_trap (o, 010) : (o->R[7] = WA, 1);
}

static inline int pdp_rts (struct pdp *o, int op)
{
	const int x = BITS (op, 0, 3);

	o->R[7] = o->R[x];
	return pdp_pop (o, o->R + x);
}

static inline int pdp_bcc (struct pdp *o, int op, int B)
{
	if (pdp_cond (o->PS, op, B))
		o->R[7] += (int8_t) op * 2;

	return 1;
}

static inline int pdp_jsr (struct pdp *o, int op)
{
	int x = BITS (op, 6, 3), D, WD, WA;

	pdp_pull_c (o, op, 2, &D, &WD, &WA);
	pdp_push_c (o, o->R[x]);

	o->R[x] = o->R[7];
	return WD ? pdp_trap (o, 010) : (o->R[7] = WA, 1);
}

static inline int pdp_srv (struct pdp *o, int op, int B)
{
	return B ? pdp_trap (o, BIT (op, 8) ? 034 : 030) : pdp_jsr (o, op);
}

#endif  /* PDP11_OP_FC_H */
