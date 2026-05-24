\# RISC-V RV32I + XMAC Custom ISA Extension



\*\*Final Year Project — Electronics (VLSI) | 2025-26\*\*



\## Project Overview

5-stage pipelined RV32I processor extended with a custom 

fused multiply-accumulate instruction (XMAC).



\*\*XMAC instruction:\*\* `xmac rd, rs1, rs2, rs3`  

\*\*Operation:\*\* `rd = (rs1 × rs2) + rs3`  

\*\*Opcode:\*\* custom-0 (0x0B) — RISC-V reserved extension space



\## Features

\- Complete RV32I 5-stage pipeline (IF→ID→EX→MEM→WB)

\- Data forwarding (EX/MEM and MEM/WB paths including rs3)

\- Load-use hazard detection and stalling

\- Branch hazard detection and flushing

\- Custom XMAC instruction for DSP acceleration

\- FPGA target: Xilinx Artix-7 (Arty A7-35T)

\- Tapeout flow: OpenLane → SKY130 (in progress)



\## Repository Structure

\- rtl/ — Verilog source files (17 modules)

\- sim/ — Testbenches

\- fpga/ — XDC constraints for Arty A7

\- docs/ — Block diagrams and documentation



\## Simulation Status

| Test | Status |

|------|--------|

| Basic Arithmetic (ADDI, ADD, SUB) | PASS |

| Data Forwarding | PASS |

| Load-Use Hazard | PASS |

| Store then Load | PASS |

| XMAC Custom Instruction | PASS |



\## Tools

\- Vivado 2025.2 (synthesis + simulation)

\- Xilinx XSim (behavioral simulation)

\- OpenLane (RTL-to-GDSII — Phase 5)



\## Target Publications

\- IEEE Embedded Systems Letters (ESL)

\- IEEE VLSID 2027





