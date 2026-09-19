# AMBA AXI
## Addressing options
- Burst must not cross 4KB boundaries to prevent them from crossing boundaries between slaves and to limit the size of the address incrementer required within slaves
  - note that AHB requires 1Kbyte boundary
- Rules for wrapping burst
  - The start address must be aligned to the size of the transfer
  - the length of the burst must be 2,4,8 or 16
## Data bus option
- The write strobe signals, WSTRB, enable sparse data transfer on the write data bus. Each write trobe signal corresponds to one bye of the write data bus. When asserted, a write strobe indicates that the corresponding byte lane of the data bus contains valid information to be updated in memory.
- Ther is one write strobe for each eight bits of the write data bus, so WSTRB[n] corresponds to WDATA[(8xn)+ 7:(8xn)]. n = 1 -> WDATA[15:8]

![alt text](image-85.png)

- The AXI protocol enables a master to use the low-order address lines to signal an unaligned start address for a burst
  - The information on the low-order address lines must be consistent with the information contained on the byte lane strobes
## Narrow transfer
- When a master generates a transfer that is narrower than its data bus, the address and control information determine which byte lanes the transfer uses. In the incrementing or wrappong bursts, different byte lanes transfer the data on each beat of the burst. In a fixed burst, the address remains constant, and the byte lanes that can be used also remain constant.
- Example
  - The burst has five transfers
  - the starting address is 0
  - each transfer is eight bits
  - the transfers are on a 32-bit bus.

![alt text](image-86.png)

## Endianness and endian mapping
- Little-endian vs Big-endian

![alt text](image-87.png)

- Little/Big/Middle-endian

![alt text](image-88.png)

- Address invariance (byte invariance)
  - the address of bytes is always preserved between big and little
    - The byte address is constant but byte significance is reversed when little- & big- endian are mixed
- Data invariance
  - The relative byte significance is preserved for data of a particular size
## Invariance
- Address invariance (byte invariance)
  - When 4-byte data is read by big- or little- endian fashion
    - The 4-byte are stored at the same address (invariant), but its significance varies depending on access size.
- Data invariance
  - 32-bit data invariance (word invariance)
    - The data of 32-bit word always the same value independent of endianness
  - 16-bit data invariance (half-word invariance)
    - The data of 16-bit word always the same value independent of endianness
  - This scheme makes it possible to inter-mix big- and little-endian system without any treatment
    - Howerver, accesses should keep its access size
      - 32-bit data invariance only guarantees data-invariance for 32-bit wide data access

## Byte invariance (Address invariance)
- Byte-invariant endianness means that a byte transfer to a given address passes the eight bits of data on the same data bus wires to the same address location
  - AXI uses nonjustified-bus with little-endian
  - Most little-endian components can connect directly to a byte-invariant interface.
  - Components that support only big-endian transfers require a conversion function for byte-invariant operation.
    - The conversion function should provide byte-invariant

![alt text](image-89.png)

## Unaligned transfers
- The AXI protocol uses burst-based addressing, which means that each transaction consists of a number of data transfers. Typically, each data transfer is aligned to the size of the transfer
  - For example, a 32-bit wide transfer is usually aligned t four-byte boundaries. However, there are times when it is desirable to begin a burst at an unaligned address
- The AXI protocol enables a master to use the low-order address lines to signal an unaligned start address for a burst. The information on the low-order address lines must be consistent with the information contained on the byte lane strobes
- Aligned and un-aligned word (4-byte) transfer on a 64-bit bus.
  - (note shaded byte-lane is not used)

![alt text](image-90.png)

## Wrapping burst
- Rules for wrapping burst
  - Bursts must not cross 4KB boundaries
  - the start address must be aligned to the size of the transfer
  - the length of the burst must be 2,4,8 or 16
- (beat size) can be equal to or smaller than data bus width
![alt text](image-91.png)

- Aligned wrapping word (4-byte) transfers on a 64-bit bus
  - (note shaded byte lane is not used)
  - AxADDR = 0x...4
  - AxSIZE = 3'b010 (4-byte)
  - AxLEN = 4'b011 (4 beats)
  - AxBURST = 2'b10 (wrapping)

![alt text](image-92.png)

## Responses
- BRESP [1:0] for write response of write transaction
  - a single response is signaled for the entire burst, and not for each data transfer within the burst
- RRESP [1:0] for read data of read transaction
  - Each transfer has its own response
- The OKAY response indicates:
  - The success of a normal access
  - The failure of an exclusive access
  - An exclusive access to a slave that does not support exclusive access
- The EXOKAY response indicates the success of an exclusive access
- The DECERR response
  - Interconnect responds for accesses to un-mapped locations
- The SLVERR response includes
  - FIFO/buffer overrun or under-run condition unsupported transfer size attempted
  - Write access attempted to read-only location
  - Timeout condition in the slave
  - Access attempted to an address where no registers are present
  - Access attempted to a disabled or powered-down function
## Atomic access
- Locked access (AXI 3 only)
  - AXI slave guarantees that there will be no accesses with different transaction ID between locked read and locked write from the same transaction ID
- Exclusive access (AXI 3 and AXI 4)
  - AXI slave reports if there are any write accesses with different transaction ID between exclusive read and exclusive write from the same transaction ID.

![alt text](image-93.png)

## Atomics instructions
- Examples of atomic operations
  - test and set
  - atomic increment
  - atomic exchange register and memory location
  - compare and swap
- Atomic increment case
  - simple approach

![alt text](image-94.png)

  - What happen when more than one try
    - "strex r0,r1,[addr]": 'r0' will have '0' when succeeded

## Atomic lock accesses
