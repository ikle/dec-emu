/*
 * PDP-11 Memory Access Operations
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PDP11_OP_MEM_H
#define PDP11_OP_MEM_H  1

#include "pdp11-core.h"

static inline int pdp_dra (struct pdp *o, int op)
{
	return (op & 010) ? pdp_read (o, o->A, &o->A) : 1;
}

static inline int pdp_lda (struct pdp *o, int op, int B)
{
	const int i = op & 7, R = o->R[i], size = B && (i & 6) != 6 ? 1 : 2;
	int X;

	if ((op & 070) == 0)				/* R */
		return 0;

	switch (op & 060) {
	default:					/* (R)           */
		o->A = R;
		return 1;
	case 020:					/* (R)+ or @(R)+ */
		o->A = R;
		return pdp_dra (o, op) && pdp_wbg (o, i, R + size);
	case 040:					/* -(R) or @-(R) */
		o->A = R - size;
		return pdp_dra (o, op) && pdp_wbg (o, i, R - size);
	case 060:					/* X(R) or @X(R) */
		if (!pdp_next (o, &X))
			return 0;

		o->A = R + X;
		return pdp_dra (o, op);
	}
}

static inline int pdp_ld (struct pdp *o, int op, int B, int n)
{
	return pdp_lda (o, op, B) && pdp_read (o, o->A, o->S + n);
}

static inline int pdp_fetch (struct pdp *o, int op, int B, int n, int *x)
{
	op = (n == 0 ? op >> 6 : op);

	if ((op & 070) == 0)
		return o->reg = 1, *x = o->R[op & 7], 1;

	return pdp_ld (o, op, B, n) && (o->reg = 0, *x = o->S[n], 1);
}

static inline int pdp_commit (struct pdp *o, int op, int B, int x)
{
	const int i = op & 7, size = B && (i & 6) != 6 ? 1 : 2;

	return o->reg ? pdp_wbg (o, i, x) : pdp_write (o, o->A, x, size);
}

#endif  /* PDP11_OP_MEM_H */
