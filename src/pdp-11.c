/*
 * PDP-11 CPU Core
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include "pdp11-core.h"

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

#include "pdp11-op-top.h"

