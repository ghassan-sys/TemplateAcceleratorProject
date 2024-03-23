# TemplateAcceleratorProject

A key property for accelerator controllers is instruction and task descriptor issue bandwidth. We would like to evaluate the open-source RISC-V processor ecosystem for processors which are most suitable to become accelerator controllers. We will define a small benchmark suit of code sequences representing typical accelerator configuration and offload execution flows for a range of accelerator programming methods such as task descriptors for MMIO accelerators and instruction sequences for extensible cores with custom instructions. We will then evaluate the available RISC-V processors using high-level instruction-count-based simulation. The goal of the project will be to create a taxonomy of processors for their suitability to different types of accelerator complexity based on accelerator input and configuration properties. We found key Accelerator traits that affect its performance significantly. We will discuss 2 main types of Accelerators (i.e. MMIO Peripheral and RoCC), discuss their key traits that affect the CPU’s performance whilst adherent to two types of Cores (Rocket and BOOM), and present the outcome in plotted graphs which highlight the main advantages/disadvantages when combining a specific accelerator with another core.

in this github repo you can find our implementation of the benchmarks, Verilog and scala code that we designed throughout the project. the repo is divided into 2 main sections each addressing a specific accelerator.
C src code can be found under: <Accelerator>/software/tests/src/
Scala code can be found under: <Accelerator>/src/main/scala/
Bash script:  <Accelerator>/src/main/scala/
Verilog implementation:  <Accelerator>/src/main/resources/vsrc/
Results: results/
the results section is divided into 4 combination of Accelerator (MMIO/ RoCC) and Cores (BOOM - OOO core / Rocket - In-Order Core) 
