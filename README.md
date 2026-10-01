# High-Performance Asymmetric UART IP Core
### Hardware-Driven Retransmission & Midpoint Oversampling Matrix in Verilog

A robust, parameterizable, full-duplex Universal Asynchronous Receiver-Transmitter (UART) hardware accelerator engineered for high-throughput embedded communication. Tailored for asymmetric clock domains, this architecture implements an advanced 16x oversampling matrix, a two-stage metastability mitigation pipeline, and a hardware-prioritized retransmission engine optimized for high-speed serial links.

---

## Key Performance Metrics

- Operating Baud Rate: 3.90625 Mbps (3.9 MHz nominal throughput)
- Frame Topology: 11-Bit Custom Packet Structure
  - 1 Start Bit (Active LOW)
  - 8 Data Bits (Least Significant Bit / LSB first transmission)
  - 1 Parity Bit (Configurable Odd Parity)
  - 1 Stop Bit (Active HIGH line termination)
- Clock Domain Architecture:
  - Transmitter Domain (t_clk): 62.5 MHz base (16 ns cycle duration; baud tick generated via a divide-by-16 counter yielding a 256 ns bit window).
  - Receiver Domain (r_clk): 200 MHz base (5 ns cycle duration; oversampling clock sliced via a 4x frequency divider to achieve a precise 16x oversampling resolution per bit period).

---

## Architectural Breakdown & Subsystem Design

### 1. Core Integration (UART_Protocol in UART.v)
The top-level wrapper unifies the transmitter and receiver into a full-duplex transceiver pipeline. It embeds a dual-stage synchronization barrier constructed from cascaded D-type flip-flops to filter out metastability risks when capturing asynchronous serial data streams from external physical lines.

### 2. Transmitter Subsystem
- Baud Rate Generator: Utilizes a dedicated parameterizable down-counter to divide the master transmit clock frequency down by a factor of 16, maintaining precise periodic baud tick assertions.
- Frame Assembler: Automatically packages parallel 8-bit broadside data arrays, injecting an odd-parity calculation bit via reduction routing logic alongside static start/stop framing boundaries.
- Transmitter Engine: Governed by an optimized sequential shift register. It features a prioritized load mechanism that intercepts standard shifting to force an immediate retransmission of a shadowed internal cache register, cleanly resolving line collision or bus conflict states.

### 3. Receiver Subsystem
- Oversampling Engine: Employs a 3-bit tracking register to divide the master 200 MHz receiver clock by 4, generating a steady 20 ns interval oversampling tick.
- Noise-Filtered FSM: Driven by a central Finite State Machine integrated with a midpoint noise-filtering counter. Midpoint evaluations execute precisely at the optimal sample index.
- FSM State Progression:
  - idle: Monitors the physical line for a valid falling-edge transition.
  - start: Validates that the line remains LOW at the precise mid-bit phase.
  - data: Sequentially shifts incoming serial levels into internal holding vectors.
  - parity: Verifies stream integrity via odd-parity bit reduction.
  - stop: Confirms high-state line termination before latching data to output registers and resetting to idle.
  - error: Triggers a recovery protocol that fires an external load flag high to demand frame retransmission.

---

## Verification & Comprehensive Test Suite Architecture

The design includes a self-checking simulation verification framework partitioned across dedicated test components (Uart_transmitter_tb.v, Uart_receiver_tb.v, and UART_tb.v).

### Transmitter Verification Coverage
1. Payload Bit-Alignment Validation: Transmits benchmark data payload 0x24 to confirm accurate bit-shifting sequences.
2. Quiescent Gate Validation: Applies data vector 0x45 without a master send strobe to verify the transmitter remains locked in an idle posture until explicitly commanded.
3. Mid-Frame Asynchronous Reset: Injects a global hardware reset 5 baud intervals into an active transmission (0x22) to test pipeline flushing and recovery behaviors.
4. Zero-Gap Back-to-Back Saturation: Floods the data pipeline continuously with extreme boundary payloads (0x00, 0x01, 0x80, 0xFF) without idle padding.
5. Extended Idle & Skew Verification: Evaluates status flag stabilization over a 44-baud idle window followed by alternating word stress patterns (0x55, 0xAA, 0x11, 0x88) to check for wakeup timing skews.
6. Collision & Over-Strobe Rejection: Attempts to force new data inputs while the core is mid-shift, proving input overwrites are successfully blocked during busy cycles.
7. Prioritized Cache Retransmission: Aborts an active transmission via reset and asserts the priority load line to force instant re-injection of the cached register.

### Receiver Verification Coverage
1. Stream Fidelity Verification: Processes a fully formatted bitstream pattern (0x12) to verify tracking accuracy.
2. Corrupted Phase Injection: Asserts an asynchronous reset 128 clock ticks into a stream to ensure invalid frames are dropped and done flags remain suppressed.
3. Parity Violation Rejection: Injects intentional bit errors into payload packet 0x07 to confirm anomaly detection and pipeline dropping.
4. Deep Silence Noise Gate: Leaves lines un-driven for 1280 sample ticks to verify the FSM does not false-trigger on floating lines.
5. Dense Multi-Packet Streaming: Back-packs four complete 11-bit frames continuously to test sampling alignment stability.
6. Stop-Bit Violation Test: Deliberately forces a LOW signal during the stop-bit window, proving that framing errors are instantly caught and flagged.
7. High-Frequency Waveform Stressing: Alternates high-transition density patterns (0x55, 0xAA, 0x0F, 0xF0) to test tracking limits under extreme toggle rates.
8. Phase Margin Drift Tolerance: Skews the baud rate frame windows from 320 to 324 scale metrics to verify that the mid-bit oversampling matrix successfully isolates misaligned data.

---

## Simulation Execution

```bash
# Compile the top module and testbench
iverilog -o sim_out UART.v Uart_transmitter_tb.v Uart_receiver_tb.v UART_tb.v

# Execute the simulation binary
./sim_out
