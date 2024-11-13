# MIPS I Functional Specification

This section discusses the functional design of the MIPS I processor.

## Adder and Logic Unit (ALU)

### Adder

The adder operation is defined as follows:

* F<sub>1</sub> — Calculate the difference of two values, otherwise calculate
  the sum of two values.
* F<sub>0</sub> — Treat operands as unsigned, otherwise as signed in two's
  complement.

```python
def Adder (S, T, F1, F0):
    return F1 ? (F0 ? S - T : (int) S - T) : (F0 ? S + T : (int) S + T)
```

### Logic Unit

The logic unit is extremely simple — F<sub>1:0</sub> encodes the required
operation:

* 00<sub>2</sub> — Compute bitwise AND.
* 01<sub>2</sub> — Compute bitwise OR.
* 10<sub>2</sub> — Compute bitwise exclusive OR.
* 10<sub>2</sub> — Bitwise invert the result of the bitwise OR calculation
  (NOR).

As an extension, the ability to calculate the logical shift of the second
operand by 16 (for the LUI operation) instead of calculating NOR has been
added.

```python
def Logic (S, T, F1, F0, LU):
    return F1 ? (F0 ? LU ? T << 16 : ~(S | T) : S ^ T) : (F0 ? S | T : S & T)
```

### A combination of the previous two units

ALU combines an adder and a logic unit:

* F<sub>2</sub> — Compute a logical operation, otherwise an addition or
  substraction operation.
* F<sub>3</sub> — Return the sign bit of the result of the selected
  operation, otherwise the result itself.

```python
def ALU (S, T, F3, F2, F1, F0, LU):
    o = F2 ? Logic (S, T, F1, F0, LU) : Adder (S, T, F1, F0)
    return F3 ? (int) o < 0 : o
```

## Operation Decoding

```python
def do_op ():
	if (C5):  return do_mem ()	# load/store
	if (C4):  return do_cop ()	# co-processor
	if (C3):  return do_imm ()	# work with immediate
	if (C2):  return do_cond ()	# compare registers and branch
	if (C1):  return do_jump ()	# jump absolute
	if (C0):  return do_regimm ()	# REGIMM class ops
	else:     return do_special ()	# SPECIAL class ops

def do_mem ():
	cop   = C4	# work with co-processor, with CPU otherwise
	store = C3	# do store, load otherwise
	zext  = C2	# zero-extend result, sign-extend otherwise

	va = S + sext (offset)
	...

def do_cop ():
	...

def do_imm ():
	T = F2 ? zext (imm) : sext (imm)	# logic or adder
	v = ALU (S, T, C[2:1] == 1, C2, C1, C0, 1)

	return wb (PC_next, rt, 0xF, v)

def do_cond ():
	cc   = (C1 ? S <= 0 : S == 0) ^ C0
	next = cc ? PC_next + sext (offset) << 2 : PC_next

	return wb (next, -, 0, -)

def do_jump ():
	next = (PC_next & (~0 << 28)) | zext (target) << 2
	we = C0 ? 0xF : 0

	return wb (next, 31, we, PC_next)

def do_regimm ():
	cc   = (S < 0) ^ T0
	next = cc ? PC_next + sext (offset) << 2 : PC_next
	we   = cc & T4 ? 0xF : 0

	return wb (next, 31, we, PC_next)

def do_special ():
	if (F5):  return do_alu ()	# adder and logic
	if (F4):  return do_mdu ()	# multiplication and division
	if (F3):  return do_jr ()	# jump by register
	else:     return do_shift ()

def do_alu (LU = 0):
	v = ALU (S, T, F3, F2, F1, F0, 0)

	return wb (PC_next, rd, 0xF, v)

def do_mdu ():
	i, we, v = -, 0, -

	if (F3):
		if (F1):  (LO, HI) = F0 ? S / T : (int) S / T	# (Q, R)
		else:     (L0, HI) = F0 ? S * T : (int) S * T
	else:
		if (F0):  i, we, v = (F1 ? lo : hi), 0xF, S
		else:     i, we, v = rd,             0xF, F1 ? LO : HI

	return wb (PC_next, i, we, v)

def do_jr ():
	if (F2):  return do_service ()	# call supervisor

	return wb (S, rd, F0 ? 0xF : 0, PC_next)

def do_shift ():
	n = (F2 ? S : sa) & 0x1f
	v = F1 ? F0 ? (int) T >> n : T >> n : T << n

	return wb (PC_next, rd, 0xF, v)
```
