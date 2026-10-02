# Sequence Detector

SystemVerilog implementation of a 1010 sequence detector.

## Implementations

- Mealy FSM – Overlapping
- Mealy FSM – Non-overlapping
- Moore FSM – Overlapping
- Moore FSM – Non-overlapping

## Verification

The designs use SystemVerilog testbenches with a 10 ns clock and the test sequence:

`1 0 1 0 1 0 0`

Waveforms were generated using VCD dumping and viewed using EPWave.

## Files

### Design files
- `mealy_overlapping.sv`
- `mealy_non_overlapping.sv`
- `moore_overlapping.sv`
- `moore_non_overlapping.sv`

### Testbenches
- `tb_mealy_overlapping.sv`
- `tb_mealy_non_overlapping.sv`
- `tb_moore_overlapping.sv`
- `tb_moore_non_overlapping.sv`
