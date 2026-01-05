/*
 * PDP-11 CPU Core Definitions
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PDP11_CORE_H
#define PDP11_CORE_H  1

#include <stddef.h>
#include <stdint.h>

#ifndef BIT
#define BIT(x, pos)      (((x) >> (pos)) & 1)
#define BITS(x, pos, n)  (((x) >> (pos)) & ~(~0 << (n)))
#endif

struct pdp {
	int R[8], PS, reg, A, S[2];
};

int pdp_read  (struct pdp *o, int A, int *x);
int pdp_write (struct pdp *o, int A, int x, int size);

/*
 * pdp_wbg   -- write-back to GPR
 * pdp_push  -- push word into stack
 * pdp_pop   -- pop word from stack
 * pdp_next  -- pull next code word
 */
static inline int pdp_wbg (struct pdp *o, int n, int x)
{
	return (o->R[n] = x, 1);
}

static inline int pdp_push (struct pdp *o, int x)
{
	const int A = o->R[6];

	return pdp_write (o, A - 2, x, 2) && pdp_wbg (o, 6, A - 2);
}

static inline int pdp_pop (struct pdp *o, int *x)
{
	const int A = o->R[6];

	return pdp_read (o, A, x) && pdp_wbg (o, 6, A + 2);
}

static inline int pdp_next (struct pdp *o, int *x)
{
	const int A = o->R[7];

	return pdp_read (o, A, x) && pdp_wbg (o, 7, A + 2);
}

#endif  /* PDP11_CORE_H */
