# Detailed Pin Mapping and Architecture (Streaming Mode)

To have utmost clarity before we write any Verilog, we must map exactly where all 24 Tiny Tapeout user pins go. 

**Architectural Intent:** We are using a **Streaming Architecture**. The external SPI Host writes instructions into a Dual-Port Instruction FIFO in real-time, while the CPUs simultaneously read and execute those instructions. This eliminates the need for a dedicated "Run/Program" mode pin, as the CPU simply stalls when the FIFO is empty and runs when instructions arrive.

## Pin Assignment Table

| Tiny Tapeout Pin | Name | Direction | Connected To | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **System Pins** | | | | |
| `clk` | CLK | Input | All Modules | Main System Clock |
| `rst_n` | RST | Input | All Modules | Active-Low Reset |
| `ena` | ENABLE | Input | Top Module | Module Enable (Required by TT) |
| **Input Pins (8)** | | | | |
| `ui_in[0]` | `SPI_CS` | Input | Instruction FIFO | SPI Chip Select for streaming instructions |
| `ui_in[1]` | `SPI_SCLK`| Input | Instruction FIFO | SPI Clock for streaming instructions |
| `ui_in[2]` | `SPI_MOSI`| Input | Instruction FIFO | SPI Master Out, Slave In (Instructions to FIFO) |
| `ui_in[7:3]` | `GP_IN[4:0]`| Input | PDATA CPU | 5 General Purpose Inputs for protocol reading |
| **Output Pins (8)**| | | | |
| `uo_out[0]` | `SPI_MISO`| Output| Instruction FIFO | SPI Master In, Slave Out (Status/Data back to Host) |
| `uo_out[7:1]` | `GP_OUT[6:0]`| Output| PDATA CPU | 7 General Purpose Outputs for protocol driving |
| **Bidi Pins (8)** | | | | |
| `uio_in[7:0]` | `BIDI_IN` | Input | PDATA CPU | Read data from the 8 bidirectional pins |
| `uio_out[7:0]`| `BIDI_OUT`| Output| PDATA CPU | Write data to the 8 bidirectional pins |
| `uio_oe[7:0]` | `BIDI_DIR`| Output| PDIR CPU | Set direction for the 8 bidirectional pins (1=Out) |

---

## Detailed Block Diagram

Here is exactly how the wires route internally:

```mermaid
graph TD
    %% External Inputs
    CLK((clk))
    RST((rst_n))
    
    SPI_CS((ui_in[0]: CS))
    SPI_CLK((ui_in[1]: SCLK))
    SPI_MOSI((ui_in[2]: MOSI))
    
    GP_IN((ui_in[7:3]: Gen In))
    
    %% Internal Modules
    FIFO[(Instruction FIFO<br>Streaming Dual-Port)]
    
    PDATA[PDATA CPU<br>Data Sequencer]
    PDIR[PDIR CPU<br>Direction Sequencer]
    
    %% External Outputs
    SPI_MISO((uo_out[0]: MISO))
    GP_OUT((uo_out[7:1]: Gen Out))
    
    BIDI_IO((uio: 8 Bidi Pins))
    
    %% Clock & Reset Routing
    CLK --> FIFO
    CLK --> PDATA
    CLK --> PDIR
    RST --> PDATA
    RST --> PDIR
    RST --> FIFO
    
    %% Streaming Routing
    SPI_CS --> FIFO
    SPI_CLK --> FIFO
    SPI_MOSI --> FIFO
    FIFO --> SPI_MISO
    
    %% Instruction Fetch Routing (Real-Time)
    FIFO == 8-bit Instr ==> PDATA
    FIFO == 8-bit Instr ==> PDIR
    
    %% PDATA I/O Routing
    GP_IN == 5-bit Data ==> PDATA
    PDATA == 7-bit Data ==> GP_OUT
    BIDI_IO == 8-bit Read ==> PDATA
    PDATA == 8-bit Write ==> BIDI_IO
    
    %% PDIR I/O Routing
    PDIR == 8-bit OE Mask ==> BIDI_IO
    
    classDef pin fill:#f9d0c4,stroke:#333,stroke-width:2px;
    class CLK,RST,SPI_CS,SPI_CLK,SPI_MOSI,GP_IN,SPI_MISO,GP_OUT,BIDI_IO pin;
    
    classDef cpu fill:#d4e1f9,stroke:#333,stroke-width:2px;
    class PDATA,PDIR cpu;
    
    classDef mem fill:#e2f9d4,stroke:#333,stroke-width:2px;
    class FIFO mem;
```
