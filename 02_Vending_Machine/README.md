# Vending Machine

## Description

This project implements an FSM-based vending machine controller using SystemVerilog.

The design supports product selection, cash payment, online payment, product dispensing, change/refund handling and transaction cancellation.

## Products

| Code | Product | Price |
|---|---|---:|
| 1 | Pen | 10 |
| 2 | Notebook | 40 |
| 3 | Water | 15 |
| 4 | Lays | 20 |
| 5 | Coke | 25 |

## FSM States

- IDLE
- SELECT_ITEM
- CASH_PAY
- ONLINE_PAY
- DISPENSE
- REFUND

## Features

- Product selection
- Cash payment
- Online payment
- Product dispensing
- Change calculation
- Refund handling
- Transaction cancellation

## Files

### Design
`vending_machine.sv`

SystemVerilog RTL implementation of the vending machine controller.

### Testbench
`tb_vending_machine.sv`

SystemVerilog testbench used for functional verification.

## Verification

The project was tested through simulation and waveform analysis using EPWave.

Test scenarios include:

1. Cash purchase of Coke
2. Online purchase of Notebook
3. Cancellation and refund

## Learning Outcome

This project provided practical exposure to FSM design, RTL coding, control logic, payment handling and testbench-based verification.
