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
#include "pdp11-op-mem.h"

static inline int pdp_swab (struct pdp *o, int op)
{
	int y;

	return	pdp_fetch  (o, op, 0, 1, &y) &&
		pdp_commit (o, op, 0, pdp_swap (o, y));
}

static inline int pdp_sop (struct pdp *o, int op, int B)
{
	const int fn = BITS (op, 6, 3), C = BIT (o->PS, 0);
	int y, z;

	if (!pdp_fetch (o, op, B, 1, &y))
		return 0;

	switch (fn) {
	case 0:  z = pdp_add (o, 0, 0, 0, 0, B, 1);  break;	/* CLR */
	case 1:  z = pdp_add (o, 0, y, 0, 1, B, 1);  break;	/* COM */
	case 2:  z = pdp_add (o, y, 0, 1, 0, B, 0);  break;	/* INC */
	case 3:  z = pdp_add (o, y, 0, 0, 1, B, 0);  break;	/* DEC */
	case 4:  z = pdp_add (o, 0, y, 1, 1, B, 1);  break;	/* NEG */
	case 5:  z = pdp_add (o, y, 0, C, 0, B, 1);  break;	/* ADC */
	case 6:  z = pdp_add (o, y, 0, 0, C, B, 1);  break;	/* SBC */
	case 7:      pdp_add (o, 0, y, 0, 0, B, 1);  return 1;	/* TST */
	}

	return pdp_commit (o, op, B, z);
}

static inline int pdp_shift (struct pdp *o, int op, int B)
{
	const int fn = BITS (op, 6, 2);
	int y, z;

	if (!pdp_fetch (o, op, B, 1, &y))
		return 0;

	const int C = BIT (o->PS, 0), H = BIT (y, B ? 7 : 15);

	switch (fn) {
	case 0:  z = pdp_shr (o, y,    C,    B   );  break;	/* ROR */
	case 1:  z = pdp_shl (o, y,    C,    B   );  break;	/* ROL */
	case 2:  z = pdp_shr (o, y,    H,    B   );  break;	/* ASR */
	case 3:  z = pdp_shl (o, y,    0,    B   );  break;	/* ASL */
	}

	return pdp_commit (o, op, B, z);
}

static inline int pdp_dop (struct pdp *o, int op, int B)
{
	const int fn = BITS (op, 12, 3);
	int x, y, z;

	B &= (fn != 6);

	if (!pdp_fetch (o, op, B, 0, &x) || !pdp_fetch (o, op, B, 1, &y))
		return 0;

	switch (fn) {
	case 1:  z = pdp_or  (o, x, 0,    0, B   );  break;	/* MOV */
	case 2:      pdp_add (o, x, y, 1, 1, B, 1);  return 1;	/* CMP */
	case 3:      pdp_and (o, x, y,    0, B   );  return 1;	/* BIT */
	case 4:  z = pdp_and (o, y, x,    1, B   );  break;	/* BIC */
	case 5:  z = pdp_or  (o, y, x,    0, B   );  break;	/* BIS */
	case 6:  z = pdp_add (o, y, x, B, B, 0, 1);  break;	/* ADD, SUB */
	}

	return pdp_commit (o, op, B, z);
}

#endif  /* PDP11_OP_ALU_H */
