# USB 1.1 Low-Speed (1.5 Mbps) TX Architecture

To achieve USB 1.1 Low-Speed transmission on the Quad-Core Accumulator ASIC at 50MHz, we must implement a deeply pipelined, multi-core architecture to handle serialization, dynamic bit-stuffing, and NRZI encoding in real-time.

At 50MHz, a 1.5 Mbps bit time is exactly **33.33 clock cycles**. We will round this to 33 clock cycles per bit (~1% error, which is well within the USB 1.1 ±1.5% tolerance).

## Pipeline Topology

The TX pipeline operates as a cascade across 3 cores. The 4th core (CPU 0) is left idle or could be used for advanced host signaling.

### CPU 3: The Serializer
* **Input:** `RX_FIFO` (Host writes raw packet bytes here).
* **Role:** Reads bytes from the FIFO and shifts them out **LSB-first** (as required by USB).
* **Output:** Pushes individual bits (0 or 1) to `SHARED_2` using the Hardware Handshake flag.

### CPU 2: The Bit Stuffer
* **Input:** Reads bits from `SHARED_2`.
* **Role:** Evaluates the incoming bit stream. It maintains a counter in an internal register (e.g., `R2`) of consecutive `1`s.
  * If the bit is `0`: Reset counter to 0. Push `0` to the next core.
  * If the bit is `1`: Increment counter. Push `1` to the next core.
    * *Bit Stuffing Trigger:* If the counter reaches 6, it immediately pushes an additional `0` to the next core, and resets the counter to 0.
* **Output:** Pushes the bit-stuffed stream to `SHARED_1` using the Hardware Handshake flag.

### CPU 1: NRZI Encoder & Pin Driver
* **Input:** Reads bits from `SHARED_1`.
* **Role:** Translates the logical bit stream into physical NRZI (Non-Return-to-Zero Inverted) bus states and drives the GPIO pins.
  * *NRZI Rules:* A logical `0` forces the bus to **toggle** its state (J → K or K → J). A logical `1` forces the bus to **maintain** its current state.
  * *Timing:* CPU 1 utilizes `TIMER_L` to strictly enforce the 33-cycle bit boundary.
* **Output:** Drives `PIN_OUT` (Pin 0 = `D+`, Pin 1 = `D-`).
  * Low-Speed Idle (J State): `D-` = 1, `D+` = 0.
  * Low-Speed K State: `D-` = 0, `D+` = 1.

## End of Packet (EOP) Generation
Because USB packets are variable length (due to bit stuffing) and require a precise End of Packet (EOP) sequence to terminate, the pipeline must know when the packet is finished.

* **Mechanism:** The Host RP2040 will write a dummy byte to **`SHARED_3`** to signal EOP.
* **Execution:** CPU 1, while waiting in its 33-cycle timer loop, will continuously poll the `FLAGS` register to check if `SHARED_3_valid` has been set by the Host.
* **EOP Sequence:** If the EOP flag is detected, CPU 1 immediately aborts the normal bit stream and drives the SE0 (Single-Ended Zero) state (`D+` = 0, `D-` = 0) for 2 bit times (66 cycles), followed by a J-State for 1 bit time (33 cycles). It then returns to the Idle loop.

## The SYNC Pattern
The USB SYNC pattern is `K J K J K J K K`. In NRZI, this perfectly corresponds to transmitting the data byte `0x80` (`10000000` in binary, sent LSB first: `0 0 0 0 0 0 0 1`).
The ASIC firmware requires no special logic for the SYNC pattern; the Host RP2040 simply prepends `0x80` as the first byte of every packet payload!
