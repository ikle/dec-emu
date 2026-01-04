/*
 * PDP-11 ALU Operations
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PDP11_OP_ALU_H
#define PDP11_OP_ALU_H  1

#include "pdp11-ex.h"

static inline int pdp_swab (struct pdp *o, int op)
{
	int D, WD, WA;

	return pdp_pull (o, op, 2, &D, &WD, &WA) &&
	       pdp_store (o, WD, WA, pdp_swap (&o->PS, D), 2);
}

static inline int pdp_sop (struct pdp *o, int op, int B)
{
	const int fn = BITS (op, 6, 3), C = BIT (o->PS, 0);
	int size = B ? 1 : 2, WD, WA, D, *ps = &o->PS, z;

	pdp_pull_c (o, op, size, &D, &WD, &WA);

	switch (fn) {
	case 0:  z = pdp_add (ps, 0, 0, 0, 0, B, 1);  break;	/* CLR */
	case 1:  z = pdp_add (ps, 0, D, 0, 1, B, 1);  break;	/* COM */
	case 2:  z = pdp_add (ps, D, 0, 1, 0, B, 0);  break;	/* INC */
	case 3:  z = pdp_add (ps, D, 0, 0, 1, B, 0);  break;	/* DEC */
	case 4:  z = pdp_add (ps, 0, D, 1, 1, B, 1);  break;	/* NEG */
	case 5:  z = pdp_add (ps, D, 0, C, 0, B, 1);  break;	/* ADC */
	case 6:  z = pdp_add (ps, D, 0, 0, C, B, 1);  break;	/* SBC */
	case 7:      pdp_add (ps, 0, D, 0, 0, B, 1);  return 1;	/* TST */
	}

	return pdp_store (o, WD, WA, z, size);
}

static inline int pdp_shift (struct pdp *o, int op, int B)
{
	const int fn = BITS (op, 6, 2), size = B ? 1 : 2;
	int D, WD, WA, *ps = &o->PS, z;

	pdp_pull_c (o, op, size, &D, &WD, &WA);

	const int C = BIT (o->PS, 0), H = BIT (D, B ? 7 : 15);

	switch (fn) {
	case 0:  z = pdp_shr (ps, D,    C,    B   );  break;	/* ROR */
	case 1:  z = pdp_shl (ps, D,    C,    B   );  break;	/* ROL */
	case 2:  z = pdp_shr (ps, D,    H,    B   );  break;	/* ASR */
	case 3:  z = pdp_shl (ps, D,    0,    B   );  break;	/* ASL */
	}

	return pdp_store (o, WD, WA, z, size);
}

static inline int pdp_dop (struct pdp *o, int op, int B)
{
	const int fn = BITS (op, 12, 3);
	int size, SD, SA, WD, WA, S, D, *ps = &o->PS, z;

	size = (B && fn != 6) ? 1 : 2;

	pdp_pull_c (o, op >> 6, size, &S, &SD, &SA);
	pdp_pull_c (o, op     , size, &D, &WD, &WA);

	switch (fn) {
	case 1:  z = pdp_or  (ps, S, 0,    0, B   );  break;	/* MOV */
	case 2:      pdp_add (ps, S, D, 1, 1, B, 1);  return 1;	/* CMP */
	case 3:      pdp_and (ps, S, D,    0, B   );  return 1;	/* BIT */
	case 4:  z = pdp_and (ps, D, S,    1, B   );  break;	/* BIC */
	case 5:  z = pdp_or  (ps, D, S,    0, B   );  break;	/* BIS */
	case 6:  z = pdp_add (ps, D, S, B, B, 0, 1);  break;	/* ADD, SUB */
	}

	return pdp_store (o, WD, WA, z, size);
}

#endif  /* PDP11_OP_ALU_H */
