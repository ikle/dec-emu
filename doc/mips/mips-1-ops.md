# MIPS I Instructions in Code Order

| type | opcode | rs     | rt    | rd     | sa    | func   | name    | args       |
| ---- | ------ | ------ | ----- | ------ | ----- | ------ | ------- | ---------- |
| R    | 000000 | 00000  | rt    | rd     | sa    | 000000 | sll     | rd, rt, sa
| R    | 000000 | -----  | ----- | -----  | ----- | 000001 | ?       |
| R    | 000000 | 00000  | rt    | rd     | sa    | 000010 | srl     | rd, rt, sa
| R    | 000000 | 00000  | rt    | rd     | sa    | 000011 | sra     | rd, rt, sa
| R    | 000000 | rs     | rt    | rd     | 00000 | 000100 | sllv    | rd, rt, rs
| R    | 000000 | -----  | ----- | -----  | ----- | 000101 | ?       |
| R    | 000000 | rs     | rt    | rd     | 00000 | 000110 | srlv    | rd, rt, rs
| R    | 000000 | rs     | rt    | rd     | 00000 | 000111 | srav    | rd, rt, rs
| R    | 000000 | rs     | 00000 | 00000  | 00000 | 001000 | jr      | rs
| R    | 000000 | rs     | 00000 | rd     | 00000 | 001001 | jalr    | rd, rs
| R    | 000000 | rs     | 00000 | 11111  | 00000 | 001001 | jalr    | rs
| R    | 000000 | -----  | ----- | -----  | ----- | 00101- | ?       |
| R    | 000000 | code   |       |        |       | 001100 | syscall | [code]
| R    | 000000 | code   |       |        |       | 001101 | break   | [code]
| R    | 000000 | -----  | ----- | -----  | ----- | 00111- | ?       |
| R    | 000000 | 00000  | 00000 | rd     | 00000 | 010000 | mfhi    | rd
| R    | 000000 | rs     | 00000 | 00000  | 00000 | 010001 | mthi    | rs
| R    | 000000 | 00000  | 00000 | rd     | 00000 | 010010 | mflo    | rd
| R    | 000000 | rs     | 00000 | 00000  | 00000 | 010011 | mtlo    | rs
| R    | 000000 | -----  | ----- | -----  | ----- | 0101-- | ?       |
| R    | 000000 | rs     | rt    | 00000  | 00000 | 011000 | mult    | rs, rt
| R    | 000000 | rs     | rt    | 00000  | 00000 | 011001 | multu   | rs, rt
| R    | 000000 | rs     | rt    | 00000  | 00000 | 011010 | div     | rs, rt
| R    | 000000 | rs     | rt    | 00000  | 00000 | 011011 | divu    | rs, rt
| R    | 000000 | -----  | ----- | -----  | ----- | 0111-- | ?       |
| R    | 000000 | rs     | rt    | rd     | 00000 | 100000 | add     | rd, rs, rt
| R    | 000000 | rs     | rt    | rd     | 00000 | 100001 | addu    | rd, rs, rt
| R    | 000000 | rs     | rt    | rd     | 00000 | 100010 | sub     | rd, rs, rt
| R    | 000000 | rs     | rt    | rd     | 00000 | 100011 | subu    | rd, rs, rt
| R    | 000000 | rs     | rt    | rd     | 00000 | 100100 | and     | rd, rs, rt
| R    | 000000 | rs     | rt    | rd     | 00000 | 100101 | or      | rd, rs, rt
| R    | 000000 | rs     | rt    | rd     | 00000 | 100110 | xor     | rd, rs, rt
| R    | 000000 | rs     | rt    | rd     | 00000 | 100111 | nor     | rd, rs, rt
| R    | 000000 | -----  | ----- | -----  | ----- | 10100- | ?       |
| R    | 000000 | rs     | rt    | rd     | 00000 | 101010 | slt     | rd, rs, rt
| R    | 000000 | rs     | rt    | rd     | 00000 | 101011 | sltu    | rd, rs, rt
| R    | 000000 | -----  | ----- | -----  | ----- | 1011-- | ?       |
| R    | 000000 | -----  | ----- | -----  | ----- | 11---- | ?       |
| I    | 000001 | rs     | 00000 | offset |       |        | bltz    | rs, offset
| I    | 000001 | rs     | 00001 | offset |       |        | bgez    | rs, offset
| I    | 000001 | rs     | 10000 | offset |       |        | bltzal  | rs, offset
| I    | 000001 | rs     | 10001 | offset |       |        | bgezal  | rs, offset
| J    | 000010 | target |       |        |       |        | j       | target
| J    | 000011 | target |       |        |       |        | jal     | target
| I    | 000100 | rs     | rt    | offset |       |        | beq     | rs, rt, offset
| I    | 000101 | rs     | rt    | offset |       |        | bne     | rs, rt, offset
| I    | 000110 | rs     | 00000 | offset |       |        | blez    | rs, offset
| I    | 000111 | rs     | 00000 | offset |       |        | bgtz    | rs, offset
| I    | 001000 | rs     | rt    | imm    |       |        | addi    | rt, rs, imm
| I    | 001001 | rs     | rt    | imm    |       |        | addiu   | rt, rs, imm
| I    | 001010 | rs     | rt    | imm    |       |        | slti    | rt, rs, imm
| I    | 001011 | rs     | rt    | imm    |       |        | sltiu   | rt, rs, imm
| I    | 001100 | rs     | rt    | imm    |       |        | andi    | rt, rs, imm
| I    | 001101 | rs     | rt    | imm    |       |        | ori     | rt, rs, imm
| I    | 001110 | rs     | rt    | imm    |       |        | xori    | rt, rs, imm
| I    | 001111 | 00000  | rt    | imm    |       |        | lui     | rt, imm
| I    | 0100zz | cop_fun |      |        |       |        | copZ    | cop_fun
| I    | 010001 | 00010  | rt    | fs     | 00000 | 000000 | cfc1    | rt, fs
| I    | 010001 | 00110  | rt    | fs     | 00000 | 000000 | ctc1    | rt, fs
| I    | 0101-- | -----  | ----- | -----  | ----- | ------ | ?       |
| I    | 011--- | -----  | ----- | -----  | ----- | ------ | ?       |
| I    | 100000 | base   | rt    | offset |       |        | lb      | rt, offset(base)
| I    | 100001 | base   | rt    | offset |       |        | lh      | rt, offset(base)
| I    | 100010 | base   | rt    | offset |       |        | lwl     | rt, offset(base)
| I    | 100011 | base   | rt    | offset |       |        | lw      | rt, offset(base)
| I    | 100100 | base   | rt    | offset |       |        | lbu     | rt, offset(base)
| I    | 100101 | base   | rt    | offset |       |        | lhu     | rt, offset(base)
| I    | 100110 | base   | rt    | offset |       |        | lwr     | rt, offset(base)
| I    | 100111 | -----  | ----- | -----  | ----- | ------ | ?       |
| I    | 101000 | base   | rt    | offset |       |        | sb      | rt, offset(base)
| I    | 101001 | base   | rt    | offset |       |        | sh      | rt, offset(base)
| I    | 101010 | base   | rt    | offset |       |        | swl     | rt, offset(base)
| I    | 101011 | base   | rt    | offset |       |        | sw      | rt, offset(base)
| I    | 10110- | -----  | ----- | -----  | ----- | ------ | ?       |
| I    | 101110 | base   | rt    | offset |       |        | swr     | rt, offset(base)
| I    | 101111 | -----  | ----- | -----  | ----- | ------ | ?       |
| I    | 110000 | -----  | ----- | -----  | ----- | ------ | ?       |
| I    | 110001 | base   | rt    | offset |       |        | lwc1    | rt, offset(base)
| I    | 110010 | base   | rt    | offset |       |        | lwc2    | rt, offset(base)
| I    | 110011 | base   | rt    | offset |       |        | lwc3    | rt, offset(base)
| I    | 1101-- | -----  | ----- | -----  | ----- | ------ | ?       |
| I    | 111000 | -----  | ----- | -----  | ----- | ------ | ?       |
| I    | 111001 | base   | rt    | offset |       |        | swc1    | rt, offset(base)
| I    | 111010 | base   | rt    | offset |       |        | swc2    | rt, offset(base)
| I    | 111011 | base   | rt    | offset |       |        | swc3    | rt, offset(base)
| I    | 1111-- | -----  | ----- | -----  | ----- | ------ | ?       |

