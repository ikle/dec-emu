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
	return (op & 010) ? pdp_read (o, &o->A) : 1;
}

static inline int pdp_lda (struct pdp *o, int op, int B)
{
	const int i = op & 7, size = B && (i & 6) != 6 ? 1 : 2;
	int X;

	if ((op & 070) == 0)				/* R */
		return 0;

	switch (op & 060) {
	default:					/* (R)           */
		return pdp_addr (o, i, 0);
	case 020:					/* (R)+ or @(R)+ */
		return pdp_addr (o, i, 0)	&&
		       pdp_put  (o, i, o->A + size) &&
		       pdp_dra  (o, op);
	case 040:					/* -(R) or @-(R) */
		return pdp_addr (o, i, -size)	&&
		       pdp_put  (o, i, o->A)	&&
		       pdp_dra  (o, op);
	case 060:					/* X(R) or @X(R) */
		return pdp_next (o, &X)		&&
		       pdp_addr (o, i, X)	&&
		       pdp_dra  (o, op);
	}
}

static inline int pdp_fetch (struct pdp *o, int op, int B, int *x)
{
	o->reg = ((op & 070) == 0);

	return o->reg ? pdp_get (o, op & 7, x) :
			pdp_lda (o, op, B) && pdp_read (o, x);
}

static inline int pdp_commit (struct pdp *o, int op, int B, int z, int y)
{
	const int i = op & 7, byte = B && (i & 6) != 6;
	const int v = B ? (y & ~0177) | (z & 0177) : z;

	return o->reg ? pdp_put (o, i, v) : pdp_write (o, z, byte);
}

#endif  /* PDP11_OP_MEM_H */
