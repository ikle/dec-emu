/*
 * PDP-11 CPU Core
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include "pdp11-core.h"

#define pdp_read_c(o, A, x) \
	do { if (!pdp_read (o, A, x))  return 0; } while (0)

#define pdp_push_c(o, x) \
	do { if (!pdp_push (o, x))  return 0; } while (0)

static int pdp_load (struct pdp *o, int reg, int A, int *x, int *WD, int *WA)
{
	return (*WD = reg) ? *x = o->R[*WA = A], 1 : pdp_read (o, *WA = A, x);
}

#define pdp_load_c(o, reg, A, x, WD, WA) \
	do { if (!pdp_load (o, reg, A, x, WD, WA))  return 0; } while (0)

static int pdp_store (struct pdp *o, int reg, int A, int x, int size)
{
	return reg ? o->R[A] = x, 1 : pdp_write (o, A, x, size);
}

#define pdp_next_c(o, x) \
	do { if (!pdp_next (o, x))  return 0; } while (0)

static int pdp_pull (struct pdp *o, int code, int size, int *x, int *D, int *A)
{
	int i = code & 7, N;

	pdp_load_c (o, 1, i, x, D, A);

	if ((i & 6) == 6)  size = 2;  /* SP or PC access */

	switch (code & 060) {
	case 020:
		pdp_load_c (o, 0, *x, x, D, A);
		o->R[i] = *x + size;
		break;
	case 040:
		pdp_load_c (o, 0, o->R[i] = *x + size, x, D, A);
		break;
	case 060:
		pdp_next_c (o, &N);
		pdp_load_c (o, 0, *x + N, x, D, A);
		break;
	}

	if (code & 010)
		pdp_load_c (o, 0, *x, x, D, A);

	if (size == 1)
		*x = (int8_t) *x;

	return 1;
}

#define pdp_pull_c(o, code, size, x, D, A) \
	do { if (!pdp_pull (o, code, size, x, D, A))  return 0; } while (0)

#include "pdp11-op-fc.h"
#include "pdp11-op-alu.h"

/* pdp11-id-top */

static inline int pdp_step_z8 (struct pdp *o, int op)
{
	const int fn = BITS (op, 3, 4);

	if (op <  64)  return pdp_sys (o, op);
	if (op < 128)  return pdp_jmp (o, op);

	switch (fn) {
	case 0:  return pdp_rts (o, op);			/* RTS */
	case 1:
	case 2:
	case 3:  return 0;					/* SPL */
	case 4:
	case 5:  return pdp_clcc (&o->PS, op);			/* CLx */
	case 6:
	case 7:  return pdp_secc (&o->PS, op);			/* SEx */
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
	case 13:
	case 14:
	case 15:  return 0;
	}
}

int pdp_step (struct pdp *o, int op)
{
	const int B = (op < 0), fn = BITS (op, 12, 3);

	switch (fn) {
	case  0:  return pdp_step_x3 (o, op, B);
	case  7:  return 0;					/* exts */
	default:  return pdp_dop (o, op, B);
	}
}
