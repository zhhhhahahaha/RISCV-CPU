# RISCV-CPU

An out-of-order RISC-V CPU supporting part of rv32i ISA



## Feature



* Using Tomasulo algorithm
* Implementing 2-bit saturating couter branch prediction of 256 entries
* Implementing directed-mapped I-cache of 256 entries
* Implementing Reorder Buffer of 15 entries, Store Load Buffer of 15 entries, Reservation of 16 entries
* Using the method that Reorder Buffer will send can_store signal to Store Load Buffer and commit store instruction to replace write buffer

## For testcase
* Passing all testcases correctly in simulation
* Passing all testcases correctly on FPGA board
* For the testcases ***testsleep, multiarray, statement_test***, you may need to reprogram the FPGA board in order to get the correct answer, but these cases can easily pass simulation

