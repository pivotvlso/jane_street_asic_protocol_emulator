# Verification Suite Guide

This repository contains a fully automated master verification suite designed to compile the custom assembly firmware, simulate the Quad-Core ASIC using Icarus Verilog, and evaluate all protocol edge cases.

## Prerequisites
To run the master script, ensure you have the following installed in your system PATH:
* **Perl** (Used to run the master script and the `assembler.pl` compiler)
* **Icarus Verilog (`iverilog` & `vvp`)** (To compile and simulate the Verilog RTL)
* **GTKWave** (Optional: for viewing the waveform `.vcd` files)

## How to Run the Tests
Simply execute the master perl script from the root directory of the repository:

```bash
perl run_tests.pl
```

### Running Specific Tests
If you only want to run specific testcases, you can pass their numbers (or parts of their filenames) as command-line arguments. For example, to only run Test 1.4 and 1.7:
```bash
perl run_tests.pl 1_4 1_7
```

### What the script does:
1. It traverses the `protocols/` folder and dynamically compiles every `.asm` file using the perl assembler.
2. It fetches every testbench in the `tests/` folder.
3. It compiles the testbench along with the core RTL using the `filelist/filelist.f` configuration.
4. It executes the simulation and parses the `stdout` to verify the CPU pushed the correct data to the Host FIFOs.
5. It safely routes all simulation artifacts (`.out` binaries and `.vcd` waveform dumps) into the `verif_output/` folder to keep your git repository perfectly clean!

## Viewing Waveforms
If a test fails (or if you want to inspect the exact cycle-accurate timing of the UART transmission), you can open the generated VCD files using GTKWave. 

For example, to view the Dual-Core Parity implementation:
```bash
gtkwave verif_output/test_1_7_uart_rx_parity.vcd
```

## Adding New Tests
If you write a new testbench (e.g., for SPI or I2C), simply name the file `test_X_X_protocol.v` and place it in the `tests/` directory. The `run_tests.py` script will automatically discover it, run it, and manage its outputs. Just ensure your testbench prints `"FAILED"` if the logic does not match your expectations!
