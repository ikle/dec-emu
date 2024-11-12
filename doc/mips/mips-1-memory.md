# MIPS I Memory Access

## Memory Access Masks

| Command | VA<sub>1:0</sub> | MEM mask | Cache mask | Reg mask |
| ------- | ---------------- | -------- | ---------- | -------- |
| lb\*    | --               | 0001     | 0000       | 1111     |
| lh\*    | -0               | 0011     | 0000       | 1111     |
| lw      | 00               | 1111     | 0000       | 1111     |
| lwl     | 00               | 1111     | 0000       | 1000     |
| lwl     | 01               | 1111     | 0000       | 1100     |
| lwl     | 10               | 1111     | 0000       | 1110     |
| lwl     | 11               | 1111     | 0000       | 1111     |
| lwr     | 00               | 1111     | 0000       | 1111     |
| lwr     | 01               | 1111     | 0000       | 0111     |
| lwr     | 10               | 1111     | 0000       | 0011     |
| lwr     | 11               | 1111     | 0000       | 0001     |
| sb\*    | 00               | 0001     | 0001       | 0000     |
| sb\*    | 01               | 0001     | 0010       | 0000     |
| sb\*    | 10               | 0001     | 0100       | 0000     |
| sb\*    | 11               | 0001     | 1000       | 0000     |
| sh\*    | 00               | 0011     | 0011       | 0000     |
| sh\*    | 10               | 0011     | 1100       | 0000     |
| sw      | 00               | 1111     | 1111       | 0000     |
| swl     | 00               | 1111     | 0001       | 0000     |
| swl     | 01               | 1111     | 0011       | 0000     |
| swl     | 10               | 1111     | 0111       | 0000     |
| swl     | 11               | 1111     | 1111       | 0000     |
| swr     | 00               | 1111     | 1111       | 0000     |
| swr     | 01               | 1111     | 1110       | 0000     |
| swr     | 10               | 1111     | 1100       | 0000     |
| swr     | 11               | 1111     | 1000       | 0000     |

* C<sub>3</sub> — store, load otherwise
* C<sub>2</sub> — zext, sext otherwise
* U = (C<sub>1:0</sub> = 10<sub>2</sub>) — unaligned access
* R = (C<sub>2:0</sub> ≠ 010<sub>2</sub>) — right word part (LSB), left
  otherwise (MSB)

### Load

```python
exec:  mem (target = rt, va = S + I, mask = C1 ? 15 : C0 ? 3 : 1)
mem:   wb (taget, data = cache (va = va >> 2), sa = va & 3, mask = mask)

wb:    m = R ? 15   >> sa     : 15   << (sa ^ 3)
       x = R ? data >> sa * 8 : data << (sa ^ 3) * 8
       y = C2 ? zext (x, mask) : sext (x, mask)
       reg (target, data = y, mask = U ? m : 15)
```

Regular (aligned) load = unaligned right load (R = 1), zext/sext for
unaligned loads redundant.

### Store

```python
exec: mem (data = T, va = S + I, mask = C1 ? 15 : C0 ? 3 : 1)
mem:  sa = va & 3
      m  = R ? mask << sa     : mask >> (sa ^ 3)
      d  = R ? data << sa * 8 : data >> (sa ^ 3) * 8
      cache (va = va >> 2, mask = m, in = d)
      wb ()

wb:   reg (mask = 0)
```

Regular (aligned) store = unaligned right store (R = 1)

### A combination of the previous two units

* C<sub>5</sub> — I/O command: set for loads and stores
* wb — write to register flag: set for loads (and for many other commands)
* S = GPR[rs]
* T = GPR[rt]
* I = sext (imm)

```python
def mips_exec_io (rt, S, T, I,  C[5:0], wb):
    D = S + I						# VA, addiu
    mask = C1 ? 15 : C0 ? 3 : 1
    R = C[2:0] != 2					# right part (LSB)

    return mips_mem (rt, T, D, mask,  C[5:0], wb, R)

def mips_mem (target, T, D, mask,  C[5:0], wb, R):
    load  = C[5:3] == 4
    store = C[5:3] == 5
    U     = C[1:0] == 2					# unaligned I/O

    sa = D[1:0]						# shift amount
    wd = R ? T    << sa * 8 : T    >> (sa ^ 3) * 8	# write data
    wm = R ? mask << sa     : mask >> (sa ^ 3)		# write mask

    rd = mips_cache (C5, D[31:2], wd, store ? wm : 0, load)

    return load ? mips_conv (target, rd, mask, sa, R, C2, U) :
                  mips_reg_write (target, D, wb ? 15 : 0)

def mips_conv (target, rd, mask, sa, R, ze, U):
    x = R ? rd >> sa * 8 : rd << (sa ^ 3) * 8
    m = R ? 15 >> sa     : 15 << (sa ^ 3)

    data = ze ? zext (x, mask) : sext (x, mask)

    return mips_reg_write (target, data, U ? m : 15)

def mips_reg_write (target[5:0], data[31:0], mask[3:0]):
    ...

def mips_cache (cs, va[31:2], in[31:0], we[3:0], oe)
    ...
```

## Co-processor load and store

* Povide va for all load/store ops.
* lcw: do not write to register (CP writes to own one).
* scw: do not provide data and mask to cache/memory (CP provides own data).

