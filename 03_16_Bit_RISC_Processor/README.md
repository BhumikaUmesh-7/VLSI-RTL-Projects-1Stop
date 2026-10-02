# 16-Bit RISC Processor

## Description

This project implements a custom 16-bit RISC-style processor using SystemVerilog.

The processor uses a five-stage pipeline with forwarding and hazard detection.

## Pipeline Stages

1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Execute (EX)
4. Memory (MEM)
5. Write Back (WB)

## Features

- 16-bit processor
- 8-register, 16-bit register file
- ALU
- Instruction memory
- Data memory
- Five-stage pipeline
- Forwarding
- Hazard detection
- Custom RISC-style instruction set
- SystemVerilog RTL

## Instruction Set

The project implements the following custom RISC-style operations:

- NOP
- ADD
- SUB
- AND
- OR
- XOR
- NOT
- LW
- SW
- LDI
- BEQ

## Verification

The processor was verified using a SystemVerilog testbench and waveform analysis.

## Important Note

This is a custom 16-bit RISC-style processor inspired by RISC principles. It is **not an official RISC-V implementation**.

## Learning Outcome

This project provided hands-on exposure to processor datapaths, pipelining, forwarding, hazard detection and SystemVerilog RTL design.
