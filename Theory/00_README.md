# AMBA AXI/AHB/APB bus and System

![alt text](image.png)
This is an overview of AMBA bus architectures and protocol bridges. The diagram is showing how different AMBA protocols can be connected to each other, mainly for verification and SoC interconnect design.

![alt text](image-1.png)

This is an AHB-to-APB bridge.

![alt text](image-2.png)

It demonstrates a mixed AMBA system, where AXI, AHB and APB coexist.

![alt text](image-3.png)

This diagram shows HW/SW co-simulation using a BFM (Bus Functional Model). The key idea is:
A C program acts like software, while the HDL simulator models the hardware. The BFM connects the software world to the AMBA bus inside the simulated hardware.

![alt text](image-4.png)
This architecture simplifies verification because developers can drive hardware tests using standard software commands, relying on the BFM to handle all the intricate protocol details instead of manually driving bus signals in a testbench.

