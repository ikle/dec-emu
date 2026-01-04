/*
 * PDP-11 ALU Core
 *
 * Copyright (c) 2024-2026 Alexei A. Smekalkine <ikle@ikle.ru>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#ifndef PDP11_EX_H
#define PDP11_EX_H  1

#include "pdp11-core.h"

static inline int pdp_clcc (struct pdp *o, int op)
{
	o->PS &= ~BITS (op, 0, 4);
	return 1;
}

static inline int pdp_secc (struct pdp *o, int op)
{
	o->PS |= BITS (op, 0, 4);
	return 1;
}

static inline int pdp_swap (struct pdp *o, int16_t x)
{
	const int16_t H = x << 8, L = (uint8_t) (x >> 8);
	const int N = (x < 0), Z = (L == 0);

	o->PS = (o->PS & ~0xF) | (N << 3) | (Z << 2);
	return H | L;
}

static inline int pdp_cond_s (int cc, int op)
{
	const int F = BITS (op, 8, 3);
	const int F2 = BIT (op, 10), F1 = BIT (op, 9), F0 = BIT (op, 8);
	const int N = BIT (cc, 3), Z = BIT (cc, 2), V = BIT (cc, 1);

	return F == 1 || ((F2 & (N ^ V)) | (F1 & Z)) == F0;
}

static inline int pdp_cond_e (int cc, int op)
{
	const int F21 = BITS (op, 9, 2), F1 = BIT (op, 9), F0 = BIT (op, 8);
	const int X = BIT (cc, 3 - F21), C = BIT (cc, 0);

	return (X | (F1 & C)) == F0;
}

static inline int pdp_cond (struct pdp *o, int op, int B)
{
	return B ? pdp_cond_e (o->PS, op) : pdp_cond_s (o->PS, op);
}

static inline int pdp_bit_cc (struct pdp *o, int16_t z, int cm, int cc)
{
	const int N = (z < 0), Z = (z == 0);

	o->PS = (o->PS & ~(0xC | cm)) | (N << 3) | (Z << 2) | cc;
	return z;
}

static inline int pdp_shift_cc (struct pdp *o, int16_t z, int C)
{
	const int N = (z < 0), Z = (z == 0), V = N ^ C;

	o->PS = (o->PS & ~0xF) | (N << 3) | (Z << 2) | (V << 1) | C;
	return z;
}

static inline
int pdp_add_cc (struct pdp *o, int16_t z, int16_t x, int16_t y, int cm, int cc)
{
	const int V = (~(x ^ y) & (z ^ y)) < 0;

	return pdp_bit_cc (o, z, (2 | cm), (V << 1) | cc);
}

static inline int pdp_or (struct pdp *o, int16_t x, int16_t y, int I, int B)
{
	const int16_t z = x | (I ? ~y : y);

	return pdp_bit_cc (o, B ? (int8_t) z : z, 2, 0);
}

static inline int pdp_and (struct pdp *o, int16_t x, int16_t y, int I, int B)
{
	const int16_t z = x & (I ? ~y : y);

	return pdp_bit_cc (o, B ? (int8_t) z : z, 2, 0);
}

static inline int pdp_shr (struct pdp *o, int16_t x, int32_t ci, int B)
{
	const int32_t X = B ? (uint8_t) x : (uint16_t) x;
	const int32_t Y = B ? -ci << 8    : -ci << 16;

	return pdp_shift_cc (o, (X | Y) >> 1, x & 1);
}

static inline int pdp_shl (struct pdp *o, int16_t x, int16_t ci, int B)
{
	const int16_t z = x << 1 | ci;

	return pdp_shift_cc (o, B ? (int8_t) z : z, BIT (x, B ? 7 : 15));
}

static inline
int pdp_add (struct pdp *o, int32_t x, int32_t y, int ci, int I, int B, int cm)
{
	const int32_t z = x + (I ? ~y : y) + ci, co = BIT (z, B ? 8 : 16) ^ I;

	return pdp_add_cc (o, B ? (int8_t) z : z, x, y, cm, co);
}

#endif  /* PDP11_EX_H */
