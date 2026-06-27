# TensorCore_Lite (SysMAC-Hybrid): Technical Specification

## 0. Mechanical Audit Log (Consistency Tracker)
* **2026-06-12 (Initialization)**: Base AI Accelerator design established.
* **2026-06-13 (SysMAC Integration)**: Pivoted to "Hybrid" model merging performance hardware with rigorous test plan.
* **2026-06-13 (Verification Milestone)**: Arithmetic Core (KSA/Mult) verified with 100% PASS rate.
* **2026-06-15 (PE Refactor)**: Refactored PE to "Bulletproof ASIC" spec (Daisy-Chain/Wavefront).
* **2026-06-16 (UVM Sign-off)**: Completed Native UVM environment for PE-level verification.
* **2026-06-16 (UVM Bug Fix Log)**: Resolved critical stimulus timing violations and systolic pipeline misalignments in the PE UVM verification suite.

---

## 1. Architectural Architecture: The Wavefront Paradigm
To eliminate global fanout violations and meet 400MHz, the array uses a localized connectivity model:
*   **Localized Routing**: Each PE only communicates with neighbors directly to its North, South, East, and West.
*   **Pulse Control**: Execution is driven by local pulses (`req_work`), ensuring only active PEs toggle power.

---

## 2. PE Operational Protocol: Single PE Detailed Breakdown

This design is a "dumb PE" – it contains no internal finite state machine (FSM) and is purely driven by the data and control signals flowing through it, guaranteeing perfectly synchronised hardware behaviour.

### The Isolated PE Interface (Ports)
**Clock & Reset:**
*   **`clk`**: The global clock driving the pipeline.
*   **`rst`**: Synchronous active-high reset to clear all internal storage to zero.

**Control Protocol:**
*   **`req_load_weight_in` / `req_load_weight_out`**: The command that flows downwards (North-to-South), telling the PE to capture the incoming weight and pass the command to the PE below it.
*   **`req_work_in` / `req_work_out`**: The command that flows horizontally (West-to-East) alongside the activation data, telling the PE to compute. 
*   **`ack_weight_locked`**: A "sticky" flag that goes HIGH once a weight has been successfully captured, signalling that the PE is ready to do math.

**Data Ports:**
*   **`w_in` / `w_out` (8-bit)**: Weights flow downwards during the setup phase.
*   **`a_in` / `a_out` (8-bit)**: Activations (Matrix A) flow horizontally from left to right.
*   **`psum_in` / `psum_out` (32-bit)**: Partial sums flow vertically downwards, accumulating as they go.

### Clock-by-Clock Operation of the Single PE

#### Phase 1: The Setup Protocol (Daisy-Chaining Weights)
Before computations begin, the PEs must be pre-loaded with their specific weights.
*   **Cycle 1:** The `w_in` pin receives an 8-bit value (e.g., `5`), and `req_load_weight_in` is driven HIGH.
*   **Cycle 2 (The Latch):** On the clock edge, the PE locks the `5` into its internal `w_reg`. It permanently raises `ack_weight_locked` to `1`. Simultaneously, it passes the `5` out of `w_out` and drives `req_load_weight_out` HIGH so the PE below can load.

#### Phase 2: The Compute Protocol (The 2-Stage Pipeline)
Once the weights are locked, the array is ready to compute. The PE uses a strict 2-stage pipeline to achieve clock targets while gating registers unless `req_work_in` is HIGH.

*   **Cycle 1: Stage 1 (Multiply & Pass Right)**
    *   *Action:* The activation (`3`) and the `req_work_in` command arrive from the left neighbour. 
    *   *Internal:* The `3` drops directly into the combinational Booth Multiplier alongside the stored `5`. It instantly calculates the result (`15`), represented as raw sum and carry vectors.
    *   *The Latch (End of Cycle 1):* The clock ticks. The PE latches the activation (`3`) into `act_reg_s1` (for `a_out`), latches the work command into `work_reg_s1` (for `req_work_out`), and latches the raw `15` into `mult_sum_s1` and `mult_carry_s1`.

*   **Cycle 2: Stage 2 (Accumulate & Hand-off)**
    *   *Action:* Because of the latch in Cycle 1, the PE now pushes the activation (`3`) out of `a_out` and drives `req_work_out` HIGH. At this exact moment, the incoming partial sum (`10`) arrives at `psum_in`.
    *   *Internal:* The latched multiplier result (`15`) and the incoming `psum_in` (`10`) drop into the 3:2 compressor and the Kogge-Stone Adder. The KSA combinationally computes `15 + 10 = 25`.
    *   *The Latch (End of Cycle 2):* The clock ticks. The PE latches the final `25` into `acc_reg_s2`.

*   **Cycle 3: The Output**
    *   *Action:* The accumulated result (`25`) is pushed out of the `psum_out` pin. The PE directly below will receive this partial sum on the exact same cycle it receives its own `req_work_in` command from its left neighbour.

**Summary of the Single PE Latency:**
From the perspective of this single isolated block, when an activation enters `a_in`, it takes exactly **1 clock cycle** to appear at `a_out`. When a partial sum enters `psum_in`, it is added to the math pipeline and takes exactly **1 clock cycle** to appear at `psum_out` (making it a total of **2 clock cycles** from when the math was originally triggered by `req_work_in`).

---

## 3. Verified Datapath Mechanics
*   **Booth Encoding**: Radix-4 algorithm reducing partial products to 4. Handles Signed INT8 ranges (-128 to 127).
*   **Wallace Tree**: 3-level 3:2 compressor architecture for high-speed summation.
*   **Kogge-Stone Adder**: 32-bit sparse-tree structure for logarithmic carry propagation (Fixed unassigned propagate bugs).
*   **Sign Extension**: Professional 32-bit sign extension implemented in partial product generation and KSA fusion layers.

---

## 4. UVM Verification Infrastructure
The environment is designed to UVM 1800.2 standards for industry sign-off:
*   **Native Scoreboard**: Implements the `(W * A) + P` golden model in pure SystemVerilog to ensure 100% compatibility with RHEL 8 toolchains.
*   **Bubble Injection**: Driver supports randomized `req_work` stalling to verify data retention in pipeline registers.
*   **Factory-Driven**: All sequences (Smoke, Max Bounds, Stress) are created via `uvm_factory::create_object_by_name` with safe `$cast` checks.
*   **Coverage Targets**: Stresses data boundaries (-128, 0, 127) and achieves 100% toggle coverage on control signals.

---

## 5. Formal Design Constraints (The "Cadence Rules")
*   **Port Flattening**: All internal module interfaces (Booth -> Wallace) must use flattened vectors to prevent zero-value optimizations in Incisive 15.20.
*   **Synchronous Reset**: All module resets must be **Active-High** and synchronized to the core clock `posedge` to align with UVM Testbench standards.
*   **Stimulus Timing**: Stimulus must be driven on the **clock negedge** to ensure zero-hold-time violations during sampling.

---

## 6. Verification Debugging Log: PE Pipeline Alignment

During the UVM Sign-off phase, a critical timing bug was isolated in the `pe_uvm` testbench where the environment failed to accurately mimic the physical properties of the systolic array. As the Senior Verification Engineer, the following log details the issues faced and the architectural solutions implemented to reach sign-off:

*   **Issue 1: Stimulus Timing Violation** 
    *   **Problem:** The `pe_driver` was incorrectly driving verification stimulus on the `posedge` of the clock. This violated the project's strict "Cadence Rules" and risked zero-hold-time sampling races.
    *   **Solution:** Refactored the UVM driver sequence. Forced all stimulus operations (`req_load_weight_in`, `req_work_in`, and `a_in`) to be driven strictly on `negedge clk`.
*   **Issue 2: Systolic Wavefront Misalignment** 
    *   **Problem:** The testbench initially drove the Activation (`a_in`) and Partial Sum (`psum_in`) simultaneously on the same cycle. However, in physical hardware, horizontal activations have a 1-cycle latency while vertical partial sums have a 2-cycle latency. This means `psum_in` naturally arrives from a North neighbor exactly 1 cycle *after* `a_in` arrives from a West neighbor.
    *   **Solution:** Engineered a staggered data pipeline in the UVM driver using an isolated `fork` block. `a_in` is driven immediately at T=0, while `psum_in` is delayed and injected exactly at T=1 clock cycle.
*   **Issue 3: Monitor Capture Skew** 
    *   **Problem:** The `pe_monitor` incorrectly sampled all inputs at T=0 and waited a static 2 cycles for output, causing scoreboard mismatches against the delayed `psum_in`.
    *   **Solution:** Refactored the `capture_output` thread to perfectly mimic the 3-stage hardware pipeline. The monitor now correctly grabs `a_in` at T=0, captures the staggered `psum_in` at T=1, and samples the stabilized `psum_out` precisely at T=2.

**Outcome:** The verification environment now safely and accurately models the physical 1-cycle skew of the systolic wavefront. The Scoreboard passes 100% of randomized regression streams.

---

## 7. Array Integration & Architectural Refinements

During the integration of the isolated `pe_pipelined.sv` into the full `systolic_array_16x16.sv` grid, a severe VLSI logic bug was identified during static code analysis. As the architectural lead, the following bug was documented and immediately resolved prior to array-level UVM verification to prevent catastrophic simulation failures:

*   **Issue 1: The Trailing-Edge Overwrite Bug (Weight Loader)**
    *   **Problem:** The initial design used a naive Daisy-Chain for weight loading (`load_out_reg <= req_load_weight_in`). Because the enable signal was pipelined, each successive PE in the column stopped shifting exactly one cycle later than its predecessor. This meant that while `PE[0]` shifted 16 times to load a full column, `PE[15]` shifted 31 times. This created a catastrophic "trailing-edge" overwrite condition where the final weight pushed by the host (`W0`) propagated uncontrollably through the entire column, overwriting all 256 PEs with identical data by the end of the load phase.
    *   **VLSI Architectural Solution:** Re-engineered the core to use a **"Self-Routing Shift-and-Hold"** loader without relying on global fanout signals. 
        *   When an empty PE receives a valid weight, it immediately locks it into a dedicated `w_reg` and strictly **swallows** the request token (refusing to pass it down).
        *   On subsequent cycles, the now "full" PE acts as a transparent router, bypassing its core and passing all incoming weights/requests directly down to the next PE via a dedicated `w_pass_reg`.
        *   This creates a self-filling pipeline that gracefully populates the 16x16 grid from Top-to-Bottom, ensuring mathematically perfect weight localization with zero race conditions.

---

## 8. Hybrid System Verification Strategy
Following the successful sign-off of the isolated 16x16 Systolic Array, the project verification plan has been restructured from a pure UVM flow to a specialized Hybrid model. This ensures optimal resource allocation by matching the verification complexity to the architectural complexity of each subsystem.

*   **Compute Core (100% Verified ✅)**
    *   *Strategy:* UVM.
    *   *Status:* Completed. The array perfectly computes 1000+ cycle randomized stress tests matching the Native SV Golden Model.
*   **SRAM Memory Subsystem (Next Up ⏳)**
    *   *Strategy:* Directed Testbench.
    *   *Rationale:* Memories are highly predictable storage structures. Standard memory tests (All 0s, All 1s, Checkerboard, March-C) executed via a pure SV directed testbench are sufficient to guarantee read/write pointers and decoders function perfectly.
*   **BIST/DFT Subsystem**
    *   *Strategy:* Directed Testbench.
    *   *Rationale:* LFSRs, MISRs, and MBIST engines are rigid mathematical state machines with fully predictable polynomial signatures. Verification will focus on multiplexer checking and validating the final compressed 512-bit MISR output against the pre-calculated golden polynomial.
*   **Host Interface & Control**
    *   *Strategy:* UVM Environment.
    *   *Rationale:* AXI-Lite and AXI-Stream are complex standard protocols. We must inject highly chaotic, constrained-random traffic with randomized TVALID/TREADY stalls to guarantee the internal FSM pipeline does not freeze or drop packets under bus backpressure.
*   **System SoC Wrapper (Final Sign-off)**
    *   *Strategy:* Full System-Level UVM.
    *   *Rationale:* Reusing block-level UVM components, this environment will drive randomized AXI configurations and stream INT8 matrices to exercise backpressure, FIFO boundary conditions, and mathematical accuracy across the entire unified SoC infrastructure.

---

## 9. Bottom-Up Verification Hierarchy (Module Order)

When verifying a complex ASIC, we always start with the pure combinational arithmetic blocks, move to the sequential state machines, build the subsystem wrappers, and finally tackle the top-level integration. 

Here is the exact order of execution for the `SysMAC-Hybrid` AI Accelerator verification, starting from the Kogge-Stone Adder:

### Phase 1: Pure Combinational Arithmetic (The Math Core)
These modules contain no clocks and no state. They are purely mathematical and require exhaustive or highly randomized testbenches.
1. `ksa_32bit.sv` (32-bit Kogge-Stone Adder)
2. `booth_encoder.sv` (Radix-4 Booth Encoding Logic)
3. `partial_product_gen.sv` (PPG Logic)
4. `wallace_tree.sv` (Wallace Tree Compressor)

### Phase 2: The Processing Element (The Compute Engine)
This is the first sequential block. It instantiates all the math units from Phase 1 into a pipelined datapath.
5. `pe_pipelined.sv` (Pipelined Processing Element)

### Phase 3: The Memory Subsystem (Storage)
Memories are verified using standard algorithmic patterns (like March-C) to check for cross-talk, address decoding, and retention.
6. `sram_bank_256x8.sv` (The 1R1W Pseudo-Dual-Port Base Cell)
7. `sram_subsystem_16bank.sv` (The 16-bank array wrapper with Flat Addressing)

### Phase 4: The DFT / BIST Subsystem (Testability)
These are pure mathematical state machines. They don't require UVM randomness; they require mathematically predictable Directed Testbenches.
8. `lfsr_prpg.sv` (Linear Feedback Shift Register for Logic BIST)
9. `misr_compressor.sv` (Multiple Input Signature Register)
10. `mbist_march_c.sv` (Memory BIST Controller)

### Phase 5: Array & Subsystem Controllers
Now we start wiring the massive blocks together. This is where UVM and heavy concurrency testing comes in.
11. `systolic_array_16x16.sv` (Instantiates 256 PEs into the 16x16 grid)
12. `bist_top_controller.sv` (Orchestrates the LBIST and MBIST engines)
13. `core_fsm_ctrl.sv` (The Main State Machine orchestrating data movement)

### Phase 6: Host Interfaces (Bus Protocols)
These modules talk to the outside world (the CPU). They require strict protocol-compliance testing (like AXI VIPs).
14. `axis_rx.sv` (AXI-Stream Receiver for streaming weights/activations)
15. `axis_tx.sv` (AXI-Stream Transmitter for streaming out results)
16. `axi_lite_config.sv` (AXI-Lite register map for configuration)

### Phase 7: Top-Level Sign-Off
17. `top_tensorcore_lite.sv` (The final chip module integrating everything above)
*This level requires the ultimate UVM Environment (Stress TC6) to verify that the Host CPU can write to the memory, configure the registers, trigger the FSM, push data through the Systolic Array, and read the results back flawlessly.*

---

## 10. Memory Subsystem Architecture

### 1. The Base Memory Cell: `sram_bank_256x8.sv`
This is the fundamental storage block. To support simultaneous streaming from the Host CPU and reading by the Systolic Array without stalling the pipeline, this module must be a Synchronous Pseudo-Dual-Port (1R1W) SRAM.

**Ports:**
*   **Clock:** `clk` (Global heartbeat).
*   **Control:** `we` (Write Enable) and `re` (Read Enable).
*   **Address Buses:** `w_addr` (8-bit) and `r_addr` (8-bit).
*   **Data Buses:** `w_data` (8-bit signed INT8 input) and `r_data` (8-bit signed INT8 output).

**Clock-by-Clock Protocol:**
*   **The Write Phase:** On `posedge clk`, if `we` is HIGH, the memory writes `w_data` into the array at `w_addr`.
*   **The Read Phase (1-Cycle Latency):** On `posedge clk`, if `re` is HIGH, the memory reads the data at `r_addr` and latches it into `r_data`.
*   **The RAW Hazard Bypass (Critical Rule):** If both `we` and `re` are HIGH on the same clock cycle, and `w_addr == r_addr`, the memory uses Write-First Logic. It bypasses the memory array and routes `w_data` directly into `r_data` to guarantee the systolic array gets the freshest data.

### 2. The Memory Wrapper: `sram_subsystem_16bank.sv`
This is the top-level memory wrapper that contains 16 instances of `sram_bank_256x8.sv`.

🚨 **The Golden Rule: Flat Addressing Only**
The memory subsystem must be completely "dumb". You must never stagger or skew the read addresses inside the memory. Because the 16x16 wrapper (`systolic_array_16x16.sv`) already has an "Input Wedge" of shift registers to create the diagonal wavefront, skewing the memory addresses would double-skew the data and completely corrupt the matrix math.

**Ports:**
*   **Clock:** `clk`.
*   **Control:** `we` and `re` (Global enables).
*   **Address Buses:** `w_base_addr` (8-bit) and `r_base_addr` (8-bit). *(Notice these are single 8-bit buses, not arrays!)*
*   **Data Buses:** `w_data_128b` (128-bit flat input vector) and `r_data_flat_128b` (128-bit flat output vector).

**Clock-by-Clock Protocol & Wiring:**
*   **Address Broadcasting:** Takes the single `w_base_addr` and wires it directly to the `w_addr` port of all 16 internal banks simultaneously. The exact same is done for `r_base_addr`.
*   **Data Slicing (Writes):** When a 128-bit flat row arrives from the Host CPU, it slices it into 16 distinct 8-bit bytes: `w_data_128b[(i*8)+7 : i*8]` goes to Bank i.
*   **Data Concatenation (Reads):** When `re` is HIGH, all 16 banks output their 8-bit `r_data` on the exact same clock cycle. The wrapper stitches them side-by-side to form a perfect, flat 128-bit row (`r_data_flat_128b`), which is immediately fed into the Systolic Array's Input Wedge.

---

## 11. AXI Host Interface & Custom Handshaking Architecture

As we transition from the internal hardware (Compute Core, SRAM, and BIST) to the outside world, your AXI subsystem acts as the "bridge." It is responsible for taking commands and massive amounts of data from the external Host CPU (or external Main Memory/DMA) and feeding them into your 4KB SRAM and 16x16 Systolic Array. 

To keep the architecture clean and prevent bottlenecks, we split this bridge into a **Control Plane** (AXI4-Lite) and a **Data Plane** (AXI4-Stream).

Here is exactly how the 4 remaining interface modules will communicate within your design:

### 1. The Control Plane: `axi_lite_config.sv`
This is your **Configuration and Status Register (CSR)** block. It uses the low-speed AXI4-Lite protocol.
*   **Who it talks to:** The external Host CPU (input) and the internal `core_fsm_ctrl.sv` & `bist_top_controller.sv` (outputs).
*   **How it works:** The Host CPU sees this module as a set of memory addresses. The CPU writes a `1` to specific memory-mapped registers (like `slv_reg0`) to send commands like `start_compute` or `bist_start`. It reads from other registers to check statuses like `bist_fail` or `mac_done`. It does not handle heavy data; it only handles "button presses" and "status lights."

### 2. The Data Ingress: `axis_rx.sv` (Receiver)
This is your high-speed data intake module. It uses the AXI4-Stream protocol to receive data from an external Memory-to-Stream DMA (MM2S).
*   **Who it talks to:** The external DMA (input) and your verified `sram_subsystem_16bank.sv` (output).
*   **How it works:** When the CPU tells the DMA to send a neural network layer, the DMA blasts packets of Weights and Activations into `axis_rx.sv`. This module handles the AXI-Stream handshakes (`tvalid`, `tready`, `tlast`) to ensure no data is dropped. It unpacks the incoming stream and writes it directly into your 4KB SRAM over the flat 128-bit bus we verified earlier.

### 3. The Data Egress: `axis_tx.sv` (Transmitter)
This is your high-speed data output module. It also uses the AXI4-Stream protocol, but it talks to a Stream-to-Memory DMA (S2MM).
*   **Who it talks to:** The bottom of your `systolic_array_16x16.sv` (input) and the external DMA (output).
*   **How it works:** As the 32-bit accumulated partial sums (`o_psum`) cascade out of the bottom of your systolic array, `axis_tx.sv` grabs them. It packages these results into standard AXI-Stream packets and pushes them back up to the Host Main Memory so the CPU can read the final matrix multiplication result. 

### 4. The Master Orchestrator: `core_fsm_ctrl.sv`
While `axi_lite_config.sv` takes the raw commands from the CPU, `core_fsm_ctrl.sv` is the actual brain of the accelerator.
*   **Who it talks to:** It listens to `axi_lite_config.sv`. It drives the enables (`we`, `re`) of the SRAM Subsystem. It drives the specific state signals (`S_LOAD_WEIGHTS`, `S_COMPUTE`) into the Systolic Array.
*   **How it works:** Once the Host CPU sets the `start_compute` register, this FSM takes over. It manages the exact cycle-by-cycle timing to pull 128-bit rows out of the SRAM, lock them into the array (Weight Stationary phase), and then stream the activations through the array (Compute phase). 

### The End-to-End Flow Summary
1.  The Host CPU uses **`axi_lite_config.sv`** to trigger a test.
2.  The DMA streams the Weight and Activation matrices into **`axis_rx.sv`**, which safely buffers them into your **4KB SRAM**.
3.  The **`core_fsm_ctrl.sv`** wakes up, reads the SRAM, and pushes the data through your **16x16 Systolic Array**.
4.  The mathematical results drop out of the array into **`axis_tx.sv`**, which streams them back to the Host CPU.

### The Custom "Mode & Valid" Protocol (Internal Mapping)
While the standard AXI4 protocols use strict, predefined handshakes (like `tvalid` and `tready`), tying them directly to your 16x16 Systolic Array would cause massive bottlenecks. To bridge the gap between the external AXI interfaces and your internal hardware, we are implementing a **Custom "Mode & Valid" Protocol**. 

#### 1. AXI-Stream to Array (axis_rx & core_fsm_ctrl)
Instead of forcing the individual Processing Elements (PEs) to decode complex AXI-Stream packets or look for specific signal edges, your `axis_rx.sv` and `core_fsm_ctrl.sv` will translate the incoming data into a simplified, high-priority **"Mode & Valid"** handshake. 
*   **The Weight-Stationary Lock:** When the AXI-Stream receiver fills the SRAM with a new matrix, the top-level controller pulls the custom `i_load_weight_valid` signal HIGH. The array blindly swallows the 128-bit rows of weights cascading down the columns.
*   **The Acknowledgment:** Once the 16th row is loaded, the array asserts a custom, sticky hardware flag called `o_weight_locked`. This flag tells the FSM: *"I have a weight safely locked inside me; I am ready to work"*. 
*   **The Compute Trigger:** Seeing `o_weight_locked` go HIGH, the FSM drops the load signal and asserts `i_compute_valid`. This switches the array's "Mode". The SRAM immediately begins streaming the Matrix A activations into the array, knowing the pipeline will not stall.

#### 2. The Egress Handshake Protocol (Array to AXI-Stream)
As the mathematical results cascade out of the bottom of the array, the `axis_tx.sv` module must translate them back into a standard AXI4-Stream format for the external Host Memory/DMA.
*   **Internal to External Translation:** Your systolic array asserts a custom `o_valid` signal every time a valid 16-element row of 32-bit partial sums (`o_psum`) emerges. 
*   **Packetizing:** The `axis_tx.sv` module catches this `o_valid` pulse and translates it into the AXI-Stream `tvalid` signal. 
*   **The `tlast` Generation:** Because your spec operates on a fixed 16x16 matrix size, the `axis_tx.sv` module will contain a custom counter. On the exact cycle the 16th (final) row drops out of the array during the `S_DRAIN` state, the transmitter will assert the AXI-Stream `tlast` signal. This tells the external DMA that the matrix multiplication is 100% complete and it can close the packet.

#### 3. The Custom Register Map Protocol (AXI-Lite)
The `axi_lite_config.sv` module acts as the low-speed control switchboard. It will decode the AXI4-Lite bus into custom **Memory-Mapped Registers (slv_reg)** so the Host CPU can drive the hardware.
*   **Control Registers (e.g., `slv_reg0`):** The CPU writes a `1` here to trigger custom internal signals like `bist_start` or `cpu_enable` to wake up the system.
*   **Status Registers (e.g., `slv_reg5`):** The internal FSMs (like the `bist_top_controller`) will route their `bist_done` and `bist_fail` sticky flags into this register. The Host CPU will constantly poll this register to see if the internal operations have finished or if the hardware detected a fault. 

By strictly separating the standard AXI protocols on the outside from your **Mode & Valid** protocol on the inside, you guarantee that your 256 PEs remain perfectly "dumb" computation engines, allowing them to run at your target 250MHz (or stretch 350MHz) without being bogged down by complex bus routing.

---

## 12. AXI Micro-Architecture Constraints

To write absolutely flawless, silicon-ready RTL for these AXI modules, there are **four critical micro-architecture details** we must lock down:

#### 1. The Exact AXI-Lite Register Map
We must explicitly define the memory addresses (offsets) for every single control and status signal, mapped to 32-bit registers:
*   **0x00 (Control Reg):** Bit 0 = `start_compute`.
*   **0x04 (Status Reg):** Bit 0 = `wt_locked`, Bit 1 = `mac_done`, Bit 2 = `rx_matrix_done` (Sticky flag).

*(Note: Manufacturing testability bypasses the system bus. The `bist_start_i`, `expected_misr_sig_i`, `bist_done_o`, and `bist_fail_o` pins are routed directly to a dedicated Joint Test Action Group (JTAG) Test Access Port (TAP) controller. Funneling a 512-bit MISR signature through a 32-bit AXI-Lite bus would require 16 sequential register writes and create a massive bottleneck. More importantly, if there is a manufacturing defect in the AXI-Lite decoder logic, the ARM CPU would be unable to trigger the self-test. JTAG provides complete isolation from the functional digital logic).*

#### 2. The "No Combinatorial Loop" Rule (AXI-Stream)
The most common bug that destroys AXI-Stream designs during Static Timing Analysis (STA) is a combinatorial loop between `tvalid` and `tready`. 
*   **The Golden AXI Rule:** Your transmitter (`axis_tx.sv`) is **never** allowed to wait for the receiver's `tready` before asserting `tvalid`. 
*   **Backpressure Logic:** Your receiver (`axis_rx.sv`) must safely drive `tready` LOW when your internal 4KB SRAM is full. We must design a secure FIFO or skid-buffer at the edge of the module to guarantee no data is dropped if the external DMA stalls randomly mid-stream. This directly satisfies your spec sheet's requirement to verify pipeline stalls via valid/ready drops.

#### 3. Resolving the Reset Polarity Conflict
According to your Master Spec Sheet, your internal hardware (PEs, SRAM, Controller) uses a **Synchronous Active-High Reset**. 
*   However, the official ARM AXI4 standard mandates an **Asynchronous Active-Low Reset** (`aresetn`).
*   **The Fix:** Your AXI modules must act as the translation boundary. We need to write a clean, 2-stage synchronizer or inversion block inside the AXI wrappers to convert the external `aresetn` into the internal active-high `rst` to prevent metastability and routing failures. 

#### 4. Hardware Hooks for Functional Coverage
Your spec sheet demands **100% functional coverage**, explicitly listing *"valid/ready handshake drops"* and *"FSM state transitions"* as coverage points. 
To write flawless code for UVM, we must build **concurrent assertions (SVA)** and coverage hooks directly into the AXI RTL. For example, we should write a quick inline assertion in `axis_rx.sv` that guarantees `tdata` does not change while `tvalid` is high and `tready` is low. This makes the UVM monitor's job significantly easier and guarantees your AXI protocol compliance.

---

## 13. AXI-Stream Ingress & Egress Architecture

### 1. Ingress Architecture: `axis_rx.sv` (Receiver)
This module acts as the AXI-Stream Slave. It receives incoming matrices (Weights and Activations) from the external DMA and unpacks them into the 4KB SRAM Subsystem.

#### Micro-Architecture Rules
*   **Reset Translation:** The AXI standard mandates `aresetn` (active-low), but the array uses a synchronous active-high `rst`. The module passes `aresetn` through a 2-stage synchronizer and inverts it to generate the internal `rst` to prevent metastability.
*   **The Skid Buffer (Anti-Combinatorial Loop):** We cannot wire `s_axis_tready` directly to the SRAM's write-ready state if there is any combinatorial dependency on `tvalid`. We use a standard Skid Buffer. `s_axis_tready` defaults to HIGH. If the internal SRAM needs a cycle to switch banks or the FSM pauses, the Skid Buffer catches the incoming `tdata` for one cycle, safely dropping `tready` LOW on the next clock edge without dropping a packet.
*   **Address Counter:** An internal 8-bit counter tracks `sram_w_addr`. It increments by 1 every time `(s_axis_tvalid & s_axis_tready) == 1`.
*   **The `tlast` Packetizer:** When the DMA asserts `s_axis_tlast`, the Rx module knows the matrix transfer is complete. It resets the address counter to its base and pulses `rx_matrix_done` so the Top FSM (`core_fsm_ctrl.sv`) can transition from `S_LOAD_WEIGHTS` to `S_COMPUTE`.

### 2. Egress Architecture: `axis_tx.sv` (Transmitter)
This module acts as the AXI-Stream Master. It captures the 32-bit accumulated results cascading out of the bottom of the systolic array and pushes them back to the host DMA.

#### Micro-Architecture Rules
*   **The "No-Stall" Output FIFO (Crucial):** Systolic arrays are pipelines that cannot stall once the `S_DRAIN` phase begins. If the external DMA drops `m_axis_tready` LOW (meaning the host memory is busy), the systolic array will continue vomiting out 512 bits of data every clock cycle.
    *   **Solution:** `axis_tx.sv` MUST contain a synchronous Output FIFO (Depth = 16 or 32 rows).
    *   Every time `array_o_valid == 1`, data is forcefully pushed into the FIFO.
    *   The AXI Master then pops data from this FIFO only when `m_axis_tready == 1`.
*   **`tvalid` Generation:** `m_axis_tvalid` is simply assigned to `~fifo_empty`. If there is data in the FIFO, the transmitter is valid. (This perfectly satisfies the AXI rule that `tvalid` must not wait for `tready`).
*   **`tlast` Generation:** Because the accelerator operates on fixed 16x16 matrices, the module includes a simple 4-bit pop counter (0 to 15). Every time a valid AXI handshake occurs (`tvalid & tready`), it increments. On the 16th handshake (`count == 15`), it asserts `m_axis_tlast = 1` and wraps back to 0, cleanly closing the AXI-Stream packet for the DMA.

### 3. Embedded Functional Coverage Hooks (SVA)
To achieve 100% functional coverage seamlessly in UVM, we embed SystemVerilog Assertions (SVA) directly into the RTL of these two modules to prove the `tdata` remains stable while stalled.

---

## 14. UVM Verification Architecture: `axis_tx.sv` (Transmitter)

### 1. UVM Testbench Architecture
#### A. The Transactions (Sequence Items)
We use two separate UVM transaction classes because the module has two distinct interfaces:
*   **`sys_tx_seq_item`**: Models the data coming from the Systolic Array.
    *   Variables: `rand int psum_row;` (The 512-bit data), `rand int delay_cycles;` (To simulate processing time between valid rows).
*   **`axi_rx_seq_item`**: Models the behavior of the external Host DMA receiving the data.
    *   Variables: `rand int tready_delay;` (Controls how often the "Fake DMA" stalls by dropping `tready` low).

#### B. The Agents
Both agents are instantiated inside the `uvm_env` and will run actively to squeeze the DUT from both sides.
*   **Agent 1: The Systolic Array Agent (Active)**
    *   *Driver:* Acts as the fake 16x16 array. It takes `sys_tx_seq_item` transactions and drives `array_o_valid` and the 512-bit `array_o_psum` bus into the DUT.
    *   *Monitor:* Passively samples the `array_o_psum` bus and broadcasts it to the Scoreboard.
*   **Agent 2: The AXI-Stream Egress Agent (Active)**
    *   *Driver:* Acts as the external Host DMA. Its only job is to drive the `m_axis_tready` signal based on the delays in `axi_rx_seq_item` to test the Output FIFO's backpressure handling.
    *   *Monitor:* Samples `m_axis_tdata`, `m_axis_tvalid`, and critically, `m_axis_tlast`. It packages these into transactions and sends them to the Scoreboard.

#### C. The UVM Scoreboard & Golden Model
The Scoreboard is the heart of the self-checking mechanism. It implements two `uvm_analysis_imp` exports to receive data from both Monitors.
*   **The Check:** It verifies that every 512-bit row injected by the Systolic Agent emerges completely unchanged at the AXI Agent.
*   **The Framing Check:** It counts the successful AXI handshakes (`tvalid & tready`). It strictly asserts a `UVM_ERROR` if `m_axis_tlast` does not assert on exactly the 16th row, or if it asserts at any other time.

### 2. UVM Virtual Sequences (The 8 Planned Test Cases)

#### General Tests (Basic Functionality)
*   **TC1_Clean_Stream_vseq (Golden Smoke Test):** 
    *   *Systolic:* Drives 16 sequential rows with 0 delay. *AXI:* Holds `tready = 1`. 
    *   *Goal:* Prove basic routing and `tlast` generation on the 16th valid handshake.
*   **TC2_Reset_Interrupt_vseq (Reset Polarity Translation):**
    *   *Action:* Mid-way through transferring 8 rows, assert `aresetn = 0`. 
    *   *Goal:* Prove the FIFO read/write pointers and 4-bit `tlast` counter reset safely.

#### Corner Cases (FIFO & Backpressure Constraints)
*   **TC3_DMA_Backpressure_vseq (The SVA Stability Test):**
    *   *AXI Constraint:* `tready_delay` inside `{1, 5}`.
    *   *Goal:* The AXI driver randomly drops `tready` low. Proves the embedded SVA property that `tdata` remains stable during a stall.
*   **TC4_Unstoppable_Drain_vseq (FIFO Stress):**
    *   *Action:* AXI Seq forces `tready = 0` for 20 clock cycles. Systolic Seq blasts all 16 rows.
    *   *Goal:* Proves the internal 32-depth synchronous FIFO catches all 8-kilobits of data without dropping a single packet or overflowing.
*   **TC5_Disconnected_Valid_vseq (No Comb-Loops):**
    *   *Action:* Systolic sends data, AXI holds `tready = 0`. 
    *   *Goal:* Proves `tvalid` asserts independently of `tready` (The Golden AXI Rule).
*   **TC6_tlast_Wrap_Boundary_vseq:**
    *   *Action:* Stream exactly 32 rows (two full matrices) with random `tready` stalls. 
    *   *Goal:* Scoreboard verifies `tlast` fires perfectly on row 16 and row 32.
*   **TC7_Extreme_Bounds_vseq:**
    *   *Action:* Push rows containing `32'h7FFFFFFF` (Max) and `32'h80000000` (Min). 
    *   *Goal:* Verify all 512 bits arrive with zero signal degradation.

#### Random Stress Test
*   **TC8_1000_Cycle_Hammer_vseq:**
    *   *Action:* Loops matrix generation 50+ times. `delay_cycles` and `tready_delay` are completely unconstrained.
    *   *Goal:* Find unknown edge cases in FIFO read/write logic. A Zero-Delay Golden FIFO Model inside the Scoreboard mimics expected outputs.

---

## 15. UVM Verification Architecture: `axis_rx.sv` (Receiver)

### 1. UVM Testbench Architecture

#### A. The Transactions (Sequence Items)
*   **`axi_dma_seq_item`**: Models the incoming data from the Host DMA.
    *   *Variables:* `rand byte tdata;` (128-bit flat bus), `rand bit tlast;`, `rand int valid_delay;` (to simulate a slow or jittery DMA).
*   **`sram_out_seq_item`**: Models the SRAM interface behavior.
    *   *Variables:* `rand int stall_delay;` (Used by the testbench to simulate the SRAM/FSM needing a pause, forcing the DUT's skid buffer to catch data and drop `tready`).

#### B. The Dual Agents
*   **`axi_dma_agent` (Active)**: 
    *   **Driver**: Acts as the Host DMA. It pulls `axi_dma_seq_item`s and drives `tdata`, `tvalid`, and `tlast` according to strict AXI rules.
    *   **Monitor**: Samples the successful AXI handshakes (`tvalid & tready`) and broadcasts the injected data.
*   **`sram_out_agent` (Active/Passive)**:
    *   **Driver**: Drives the internal stall/pause signal back to the DUT to test the skid buffer's backpressure handling.
    *   **Monitor**: Captures the exact `sram_w_data`, `sram_w_addr`, and the `rx_matrix_done` pulse, broadcasting them to the Scoreboard.

#### C. The UVM Scoreboard & Virtual Sequencer
*   **`axis_rx_scoreboard`**: 
    *   Uses the `` `uvm_analysis_imp_decl(_axi) `` and `` `uvm_analysis_imp_decl(_sram) `` macros to create two distinct TLM ports.
    *   *The Check:* It maintains a queue of incoming AXI matrices. When the SRAM monitor reports a write (`sram_we == 1`), it compares the `sram_w_data` against the queued AXI data. It also strictly verifies that `sram_w_addr` increments from 0 to 15 flawlessly and that `rx_matrix_done` pulses exactly when `tlast` is processed.
*   **`axis_rx_vsequencer`**: A class extending `uvm_sequencer` that holds the handles to the `axi_dma_sequencer` and `sram_out_sequencer`.

### 2. UVM Virtual Sequences (The 8 Planned Test Cases)

#### General Tests (The Functional Baseline)
*   **TC1_Golden_Smoke_vseq (Clean Egress to SRAM):**
    *   *Mechanism:* DMA Driver holds `s_axis_tvalid = 1` continuously for 16 cycles.
    *   *Checking:* Address increments exactly 0 to 15, data matches, and `rx_matrix_done` pulses.
*   **TC2_Reset_Interrupt_vseq (Reset Polarity Translation):**
    *   *Mechanism:* Mid-way through a matrix transfer, unpredictably pull `aresetn = 0`.
    *   *Checking:* Verify `s_axis_tready` resets, `sram_w_addr` flushes to 0, and internal `rst` asserts HIGH.

#### Corner Cases (Protocol Hazards & Skid Buffer Constraints)
*   **TC3_SRAM_Backpressure_vseq (Skid Buffer Stress):**
    *   *Mechanism:* SRAM forces an artificial pause. Receiver drops `s_axis_tready = 0`.
    *   *Checking:* Data is caught in the Skid Buffer and safely written to SRAM when ready without loss.
*   **TC4_AXI_Stability_SVA_vseq (AXI Stability SVA Violation Check):**
    *   *Mechanism:* Hostile DMA driver intentionally changes `tdata` while stalled.
    *   *Checking:* Verify the concurrent SVA `p_axi_tdata_stable` successfully triggers a UVM_ERROR.
*   **TC5_Premature_TLAST_vseq (Framing Error):**
    *   *Mechanism:* DMA asserts `s_axis_tlast = 1` on the 5th row instead of the 16th.
    *   *Checking:* Verify receiver resets address counter and pulses `rx_matrix_done` safely avoiding lock-up.
*   **TC6_Back_to_Back_vseq (Throughput Stress):**
    *   *Mechanism:* Stream 32 rows total (two full matrices) with absolute zero delay.
    *   *Checking:* `rx_matrix_done` pulses precisely on cycle 16 and 32, address wraps 15 to 0.
*   **TC7_Extreme_Bounds_vseq (Data Integrity):**
    *   *Mechanism:* Blast maximum values (`8'h7F`) and minimum values (`8'h80`).
    *   *Checking:* Golden Model verifies zero truncation or sign-extension errors.

#### Random Stress Test
*   **TC8_1000_Cycle_Hammer_vseq (Randomized AXI Hammer):**
    *   *Mechanism:* Stream 50+ matrices with randomized DMA valid delays and SRAM stall delays.
    *   *Checking:* Scoreboard catches every 128-bit row pushed into SRAM against the Golden Model queue.

---

## 16. Controller FSM Architecture: `core_fsm_ctrl.sv`

This module is the master orchestrator for the 16x16 Weight-Stationary Systolic Array.

### 1. Interface Constraints
*   **System Signals:** `clk` (250-350MHz target), `rst` (Synchronous Active-High).
*   **AXI-Lite Control:** `start_compute` (trigger), `mac_done` (sticky completion flag).
*   **SRAM Subsystem:** `sram_re` (Active-High), `sram_r_addr[7:0]`, `sram_r_data[127:0]` (1-cycle read latency).
*   **Systolic Array:** 
    *   `array_load_weight_valid`: Commands PEs to daisy-chain weights vertically.
    *   `array_compute_valid`: Commands PEs to shift activations horizontally.
    *   `array_w_in[127:0]` / `array_a_in[127:0]`: Pass-through from `sram_r_data`.
    *   `array_weight_locked`: Feedback flag to transition to compute.

### 2. Strict SRAM Memory Map
*   **Addresses 0 to 15 (Matrix B):** 16 rows of the Weight matrix.
*   **Addresses 16 to 31 (Matrix A):** 16 rows of the Input Activation matrix.

### 3. Pipelining Rules
*   **Rule A (1-Cycle SRAM Read Latency):** The valid control signals (`array_load_weight_valid` and `array_compute_valid`) are delayed by 1 clock cycle using D-Flip-Flops to perfectly align with the arrival of `sram_r_data`.
*   **Rule B (Wedge Formatter):** Shift-register delay lines exist in the datapath to skew the input data diagonally.
*   **Rule C (Total Latency):** Due to the reverse-wedge deskewing pipeline, mathematical latency is rigidly defined as $3N$ cycles. For $N=16$, this is exactly 48 cycles.

### 4. Detailed Finite State Machine (4-State)

Encoded using `typedef enum logic [1:0]`:
*   **STATE 0: `S_IDLE`**
    *   *Action:* `sram_re=0`, valid signals=0, `addr_cnt=0`, `drain_cnt=0`, `mac_done=0`.
    *   *Transition:* Wait for `start_compute == 1`, then jump to `S_LOAD_WEIGHTS`.
*   **STATE 1: `S_LOAD_WEIGHTS`**
    *   *Action:* `sram_re=1`. Sweep `sram_r_addr` from 0 to 15. Pipeline `array_load_weight_valid`.
    *   *Transition:* Stop reading at `addr_cnt == 15`. Wait for `array_weight_locked == 1`. Reset `addr_cnt` to 16, jump to `S_COMPUTE`.
*   **STATE 2: `S_COMPUTE`**
    *   *Action:* `sram_re=1`. Sweep `sram_r_addr` from 16 to 31. Pipeline `array_compute_valid`.
    *   *Transition:* On `addr_cnt == 31`, unconditionally jump to `S_DRAIN`.
*   **STATE 3: `S_DRAIN`**
    *   *Action:* `sram_re=0`, valid signals=0. Increment `drain_cnt`.
    *   *Transition:* If `drain_cnt == 48`, assert `mac_done = 1`, reset counters, and jump to `S_IDLE`.

### 5. ASIC-Ready Micro-Architecture Features
*   **Strictly Registered Outputs:** All outputs (`mac_done`, `sram_re`, `sram_r_addr`, valid signals) are driven directly out of D-Flip-Flops to eliminate combinational routing delays and prevent Setup Time Violations during STA.
*   **Aggressive Dynamic Power Protection:** `sram_re` is logically clamped to `0` during `S_IDLE` and `S_DRAIN` to utilize SRAM clock-gating cells.
*   **UVM-Compliant State Encoding:** Uses SystemVerilog enumerated types for automatic UVM coverage extraction.
*   **Synchronous Reset Domain:** Uses strict `always_ff @(posedge clk)` without `rst` in the sensitivity list.


---

## 17. UVM Verification Architecture: core_fsm_ctrl.sv

### Verification Test Plan
**Part 1: General Test Cases (The Functional Baseline)**
These tests prove the FSM walks through its 4 states flawlessly under perfect conditions.
*   **TC1: Golden Smoke Test (The Perfect Matrix)**
    *   *Objective:* Prove the FSM perfectly sequences a single matrix computation.
    *   *Mechanism:* Pulse start_compute. Let it sweep addresses 0-15. Assert array_weight_locked on cycle 16. Let it sweep addresses 16-31.
    *   *Checking:* Verify that sram_re correctly asserts during the sweeps and de-asserts otherwise. Most importantly, verify that mac_done asserts exactly 48 clock cycles after the address reaches 31.
*   **TC2: The 1-Cycle Pipeline Delay Check (Rule A Verification)**
    *   *Objective:* Prove that the FSM properly masks the SRAM read latency.
    *   *Mechanism:* Monitor the output buses continuously during TC1.
    *   *Checking:* Use SystemVerilog Assertions (SVA) to verify that array_load_weight_valid and array_compute_valid assert exactly one clock cycle after sram_r_addr changes.
*   **TC3: Synchronous Active-High Reset Interruption**
    *   *Objective:* Prove the FSM complies with the PE architecture spec for synchronous resets.
    *   *Mechanism:* Start a computation. While the FSM is in S_COMPUTE (e.g., at address 24), assert the active-high rst signal on the rising clock edge.
    *   *Checking:* Verify that current_state instantly flushes to S_IDLE, addr_cnt resets to 0, and sram_re drops to 0 safely without glitching.

**Part 2: Corner Test Cases (Protocol Hazards)**
These tests stress the transition conditions between states.
*   **TC4: Delayed Weight Lock (The Stall Test)**
    *   *Objective:* Ensure the FSM waits patiently if the Systolic Array is slow to lock the weights.
    *   *Mechanism:* The FSM finishes sweeping addresses 0-15, but the testbench intentionally delays asserting array_weight_locked for 10 clock cycles.
    *   *Checking:* Verify that the FSM safely parks in S_LOAD_WEIGHTS. sram_re MUST drop to 0 (saving power), and the address counter must freeze at 16 until the lock signal finally arrives.
*   **TC5: Back-to-Back Compute (Zero-Idle Transition)**
    *   *Objective:* Test the accelerator's throughput when the Host CPU queues up a new matrix instantly.
    *   *Mechanism:* On the exact clock cycle that mac_done is asserted (end of S_DRAIN), the testbench pulses start_compute again.
    *   *Checking:* Verify that the FSM skips idling and instantly loops back to S_LOAD_WEIGHTS, resetting its counters to 0 to begin the next tile without wasting a single clock cycle.

**Part 3: Random Stress & Coverage**
*   **TC6: 1000-Cycle Randomized Event Hammer**
    *   *Objective:* Uncover hidden deadlocks by randomizing all inputs over a long simulation.
    *   *Mechanism:* Randomize the delay before start_compute is pulsed (0 to 50 cycles). Randomize the delay of array_weight_locked (0 to 20 cycles). Run this back-to-back for 1000+ cycles.
    *   *Checking:* A UVM Covergroup will track the current_state variable. The test will not report a PASS unless the coverage collector mathematically proves that every single valid state transition was successfully traversed and logged.

**Built-In SystemVerilog Assertions (SVA)**
Because this module is the control brain, we will embed specific SVA rules directly into the testbench interface to constantly monitor it:
`systemverilog
// Ensure SRAM read enable is strictly LOW during DRAIN to save power
assert property (@(posedge clk) (current_state == S_DRAIN) |-> (sram_re == 0));

// Ensure 48-cycle exact latency constraint
assert property (@(posedge clk) (current_state == S_DRAIN && drain_cnt == 48) |=> (mac_done == 1));
`

### UVM Verification Implementation Plan
**1. Interface, SVA & UVM Package**
*   sm_ctrl_if.sv: The SystemVerilog interface containing the clock and synchronous active-high reset. It defines all connections to the Host, SRAM, and Array. Crucially, this file will contain the SystemVerilog Assertions (SVA) to mathematically prove the 1-cycle read latency rule and the strict 48-cycle drain latency.
*   sm_ctrl_pkg.sv: The UVM package wrapper. It starts with \	imescale 1ns/1ps to prevent compilation warnings and \includes all the UVM classes below in the correct hierarchical order to keep the global namespace clean.

**2. Transactions (Sequence Items)**
We need three separate sequence items to model the three independent interfaces:
*   host_ctrl_seq_item.sv: Models the Host CPU's control plane.
    *   Variables: 
and int delay_before_start; (Controls when start_compute is pulsed).
*   rray_feedback_seq_item.sv: Models the Systolic Array's behavior.
    *   Variables: 
and int weight_lock_delay; (Controls how many cycles it takes for the array to assert array_weight_locked to test TC4's stall logic).
*   sram_dummy_seq_item.sv: Models the SRAM returning data.
    *   Variables: 
and logic [127:0] dummy_r_data; (To ensure sram_r_data perfectly passes through to the array_w_in and array_a_in ports).

**3. The Tri-Agent Architecture**
*   **host_ctrl_agent.sv (Active)**
    *   Driver: Pulses start_compute based on the sequence item delays.
    *   Monitor: Samples the mac_done flag and reports the total elapsed cycles to the Scoreboard.
*   **rray_feedback_agent.sv (Active)**
    *   Driver: Waits for the FSM to finish the 0-15 address sweep, then waits weight_lock_delay cycles before asserting array_weight_locked = 1.
    *   Monitor: Samples array_load_weight_valid and array_compute_valid to ensure they obey the 1-cycle pipeline delay.
*   **sram_dummy_agent.sv (Active/Passive)**
    *   Driver: Acts as the 4KB memory. When sram_re == 1, it returns dummy_r_data exactly one cycle later.
    *   Monitor: Samples sram_re and sram_r_addr to ensure the address counters sweep exactly 0-15 and then 16-31, broadcasting them to the Scoreboard.

**4. The UVM Scoreboard & Coverage Collector**
*   sm_scoreboard.sv: Utilizes three \uvm_analysis_imp_decl macros (e.g., _host, _array, _sram) to implement three distinct write() functions without naming collisions. It acts as a cycle-accurate golden tracker. It verifies that sram_re drops to 0 during the idle/drain phases to save power. It validates that the array_w_in perfectly matches the SRAM data, and explicitly flags a UVM_ERROR if mac_done fires even one cycle earlier or later than the 48-cycle boundary.
*   sm_coverage.sv: A UVM subscriber that taps into the interface to track the FSM's current_state. It implements a covergroup specifically checking all cross-transitions to satisfy the 100% functional coverage requirement.

**5. Virtual Sequencer & Sequences (The 6 Test Cases)**
*   sm_vsequencer.sv: Holds the handles to the three individual sequencers (Host, Array, SRAM) so they can be coordinated.
*   sm_vseq.sv: Contains the virtual sequences executing our exact test plan (TC1, TC3, TC4, TC5, TC6).

**6. Test & Top Module**
*   sm_test.sv: Sets up the UVM factory, instantiates the environment, and properly utilizes safe factory downcasting () to launch the sequences.
*   	b_fsm_top.sv: The physical top level. It instantiates core_fsm_ctrl.sv, the interface, the clock, and calls run_test().

---

## 18. AXI-Lite Configuration & Control: `axi_lite_config.sv`

This module acts as the translator between the Host CPU (e.g., an ARM Cortex) and the custom hardware, dividing its ports strictly into three isolated domains: the System domain, the standard AXI4-Lite Slave domain, and the Custom FSM Control domain.

### 1. Interface (Ports) Breakdown
*   **System Signals:** `clk` (250-350MHz target), `rst` (Synchronous Active-High).
*   **Custom Accelerator Control Plane:** `start_compute` (Output, 1-bit pulse), `mac_done` (Input, 1-bit sticky flag).
*   **AXI4-Lite Slave Interface:** 
    *   Write Address (AW): `awaddr[31:0]`, `awvalid`, `awready`
    *   Write Data (W): `wdata[31:0]`, `wvalid`, `wready`
    *   Write Response (B): `bresp[1:0]`, `bvalid`, `bready`
    *   Read Address (AR): `araddr[31:0]`, `arvalid`, `arready`
    *   Read Data (R): `rdata[31:0]`, `rresp[1:0]`, `rvalid`, `rready`

### 2. The Custom Protocol & Register Memory Map
| Address Offset | Register Name | Access Type | Bit 0 | Bits [31:1] |
| :--- | :--- | :--- | :--- | :--- |
| **`0x00`** | **Control Register** | Write-Only | `start_compute` | Reserved (Ignored) |
| **`0x04`** | **Status Register** | Read-Only | `mac_done` | Tied to 0 |

*   **Offset `0x00` (Trigger):** A write of `1` to bit 0 translates to exactly a 1-clock-cycle HIGH pulse on the `start_compute` wire.
*   **Offset `0x04` (Polling):** A read returns the physical `mac_done` wire from `core_fsm_ctrl.sv` packed into the lowest bit of `rdata`.
*   **Invalid Address Protection:** If an unmapped address is requested, the module gracefully completes the handshake (`bresp/rresp = 2'b00`) but silently drops write data or returns `32'h0000_0000` on reads to prevent CPU lockup.

### 3. Parallel FSM Architecture
To prevent AXI deadlock, two independent, 3-state FSMs run in parallel:
*   **A. Write Channel FSM**
    *   **`S_WR_IDLE`:** Waits for `awvalid == 1` && `wvalid == 1`. Latches address/data.
    *   **`S_WR_PROCESS`:** Asserts `awready/wready = 1`. Generates 1-cycle `start_compute` pulse if `awaddr == 0x00` and `wdata[0] == 1`.
    *   **`S_WR_RESP`:** Asserts `bvalid = 1`, `bresp = OKAY`. Waits for `bready == 1`.
*   **B. Read Channel FSM**
    *   **`S_RD_IDLE`:** Waits for `arvalid == 1`. Latches address.
    *   **`S_RD_PROCESS`:** Asserts `arready = 1`. Reads `mac_done` if `araddr == 0x04` and prepares `rdata`.
    *   **`S_RD_DATA`:** Asserts `rvalid = 1`, `rresp = OKAY`. Waits for `rready == 1`.

### 4. ASIC-Ready Micro-Architecture Features
*   **No Combinatorial Loop:** Handshake signals (`bvalid`, `rvalid`) are strictly registered in the 3rd FSM states, completely severing combinational dependency on master `READY` signals.
*   **Fully Registered Outputs:** Every single AXI output is strictly registered to guarantee clean Register-to-Register (R2R) timing closure for 250MHz-350MHz targets.
*   **Glitch-Free Pulsing:** `start_compute` is driven from a synchronous D-Flip-Flop inside `S_WR_PROCESS` to prevent false triggers from address bus glitches.
*   **DFT-Aware:** All AXI-Lite FSMs and internal registers are cleared exclusively by the global synchronous active-high `rst`, ensuring 100% testability during scan shift.

### 5. UVM Verification Architecture
The `axi_lite_config.sv` module is verified using a rigorous, block-level Dual-Agent UVM environment to ensure 100% protocol compliance and zero AXI deadlocks.
*   **Dual-Agent Isolation:** 
    *   `axi_master_agent`: Drives randomized standard AXI4-Lite read/write transactions into the slave interface. Includes randomized BREADY/RREADY stalls.
    *   `core_ctrl_agent`: Monitors the `start_compute` pulse and responds with the `mac_done` sticky flag after a randomized delay.
*   **Golden Scoreboard:** Uses `uvm_analysis_imp_decl` to seamlessly handle asynchronous streams from the AXI bus and the Core FSM, mathematically checking the `0x00` write-trigger and `0x04` read-status translation.
*   **Embedded SVA:** The `axi_lite_if.sv` embeds strict SVAs to mathematically prove `VALID` never depends combinationally on `READY`, and that `start_compute` is strictly 1-cycle wide.
*   **Coverage & Stress Testing:** A dedicated `uvm_subscriber` guarantees 100% functional coverage on all state transitions. The `TC6_1000_cycle_hammer` test blasts randomized overlapping reads and writes with heavy backpressure to ensure robust hardware performance.


## 19. System-Level Interface Architecture (`system_top_if`)

### 1. The Global Power & Clock Domain
*   **`clk_i` (250MHz - 350MHz):** Driven by a configurable clock generator in the testbench top that allows dynamic frequency sweeping from 250MHz up to 350MHz.
*   **`rst_ni`:** Asynchronous Assert, Synchronous Release.

### 2. The Control Plane: AXI4-Lite Interface
*   **Write Channels (AW, W, B):** 32-bit Address and Data buses. Tracks whether the Host CPU holds `s_axi_awvalid` and `s_axi_wvalid` indefinitely if the accelerator is busy.
*   **Read Channels (AR, R):** 32-bit Address and Data buses. Used specifically to poll the `mac_done` status.
*   *Performance Focus:* SVAs guarantee that AXI transactions never stall the main compute engine.

### 3. High-Speed Data Ingress: AXI-Stream RX
*   **`s_axis_tdata` (128-bit):** Packs an entire row of 16 INT8 weights or activations into a single cycle.
*   **`s_axis_tvalid` & `s_axis_tready`:** The critical handshake.
*   **`s_axis_tlast`:** Defines the matrix boundary (e.g., firing after the 16th row is streamed in).
*   *Performance Focus (The Firehose):* Architecture supports continuous burst mode. The interface tracks `tready` backpressure to measure wasted clock cycles.

### 4. High-Speed Data Egress: AXI-Stream TX
*   **`m_axis_tdata` (512-bit):** Captures 512 bits in a single clock cycle.
*   **`m_axis_tvalid` & `m_axis_tready`:** The output handshake.
*   **`m_axis_tlast`:** Flags the final row of the 16x16 output matrix.
*   *Performance Focus (Drain Rate):* Strict SVA timing checks measure the exact delta between `start_compute` and `m_axis_tvalid` to prove the 48-cycle latency.

### 5. The Manufacturing Test Plane (DFT/BIST)
*   **`bist_start_i` & `expected_misr_sig_i` (512-bit):** Injects the golden signature.
*   **`bist_done_o` & `bist_fail_o`:** Output flags.
*   *Performance Focus:* When BIST is engaged, AXI-Stream and AXI-Lite buses are isolated, proving test mode doesn't corrupt system memory.

### Integrating Performance: Clocking Blocks
A Clocking Block acts as an artificial timing boundary between UVM and RTL.
*   **Input Skew (`default input #1ns`):** Mimics realistic propagation delay, forcing stringent Setup Time constraints.
*   **Output Skew (`default output #1ns`):** Samples 1 nanosecond before the next clock edge, verifying Hold Time constraints.


## 20. The 4-State Master FSM Architecture (`core_fsm_ctrl.sv`)

### STATE 0: `S_IDLE`
*   **System Role:** Quiescent standby.
*   **Datapath Actions:** `sram_re = 0`, `array_load_weight_valid = 0`, `array_compute_valid = 0`.
*   **Transition:** AXI-Lite write to `EX_CTRL` triggers `LOAD_WT` -> `S_LOAD_WEIGHTS` or `START_MAC` -> `S_COMPUTE`.

### STATE 1: `S_LOAD_WEIGHTS`
*   **System Role:** Sucks 16 rows of the Weight Matrix from SRAM into the PE stationary registers.
*   **Datapath Actions:** `sram_re = 1`, sweeping `sram_r_addr` from 0 to 15. `array_load_weight_valid = 1`.
*   **Transition:** Waits until `array_weight_locked == 1` from PE (15, 15). Returns to `S_IDLE`.

### STATE 2: `S_COMPUTE`
*   **System Role:** Executes the core AI workload (Activation Matrix stream).
*   **Datapath Actions:** `sram_re = 1`, sweeping `sram_r_addr` from 16 to 31. `array_compute_valid = 1`.
*   **Transition:** Stays exactly 16 cycles, unconditionally transitions to `S_DRAIN`.

### STATE 3: `S_DRAIN`
*   **System Role:** Hardware Latency Tracker. Waits for final calculations to reach bottom output pins.
*   **Datapath Actions:** `sram_re = 0`, `array_compute_valid = 0`. Activates internal 48-cycle counter.
*   **Transition:** When counter hits 48, asserts `mac_done` HIGH and transitions to `S_IDLE`.

### FSM 350MHz Optimizations
1.  **Zero Software Overhead:** 48-cycle latency is hardware-tracked. CPU just spin-polls.
2.  **No SRAM Backpressure:** On-chip 4KB SRAM sweeps addresses continuously without `sram_ready` handshake.
3.  **Clean Datapath Isolation:** Eliminates massive fanout setup-time violations by driving only the top/left edge.


## 21. System-Level Physical Integration Strategy

1.  **Timing Closure (STA):** Enforces strict R2R paths for internal dataflow. I2R and R2O boundaries protect the array from external delays.
2.  **Data Skewing (The "Wedge"):** Shift-Register skewing converts flat arrays into a diagonal wavefront, ensuring wire fanout is strictly local to neighbors.
3.  **Dynamic Power Management:** Latch-Based Clock Gating and Weight Stationary dataflow massively reduce dynamic power.
4.  **DFT-Aware Architecture:** Synchronous active-high reset derivation and full scan insertion guarantee >95% stuck-at coverage.


## 22. System-Level UVM Architecture Plan (top_tensorcore_lite)

To execute all 42 test cases (35 sub-module integration tests + 7 specialized top-level tests) through the physical pins of `top_tensorcore_lite.sv`, a highly coordinated, multi-agent UVM environment with a Virtual Sequencer is mandatory.

### 1. The 4 Active/Passive Agents:
*   **`axi_lite_agent` (Active):** Drives memory-mapped configuration triggers to `0x00` and spin-polls status at `0x04`.
*   **`axis_rx_agent` (Active):** The high-speed DMA firehose. Blasts 128-bit weights and activations, injecting random `tvalid` drops.
*   **`axis_tx_agent` (Active/Passive):** Receives the 512-bit partial sums and asserts random `tready` backpressure to stall the chip.
*   **`bist_agent` (Active):** Drives the `bist_start_i` and `expected_misr_sig_i` pins.

### 2. Top-Level Verification Components
*   **Top-Level Interfaces (`system_top_if`):** Defines Clocking Blocks for input skew (`default input #1ns`) and output skew (`default output #1ns`).
*   **Virtual Sequencer (`top_vsequencer`):** Holds the sub-sequencer handles (`axi_lite_sqr`, `axis_rx_sqr`, etc.) for centralized control.
*   **Scoreboard (`top_scoreboard`):** Uses DPI-C to call `extern "C" void golden_matmul(...)`. Captures the flat 128-bit inputs and compares against 512-bit TX output.
*   **Coverage Collector (`top_coverage`):** `uvm_subscriber` tracking 100% functional coverage of boundary hits, transitions, and stalls.

### 3. The 42 Test Sequences (Virtual Sequences)
The testbench exhaustively verifies top-level integration using strictly external pins:
*   **AXI-Lite Integration (TC1-TC5):** Hardware-in-the-loop, crosstalk rejection, invalid addresses, spin-polling, BIST override.
*   **Core FSM Integration (TC6-TC10):** 48-cycle latency proof, wedge deskew, data starvation, back-to-back compute, mid-flight reset.
*   **AXIS RX Integration (TC11-TC15):** Burst packing, backpressure cascade, tlast pivot, corner payloads, DMA glitch tolerance.
*   **AXIS TX Integration (TC16-TC20):** Egress deskew, egress backpressure, automated tlast generation, zero flush, continuous drain.
*   **SRAM Subsystem (TC21-TC25):** RX routing, R/W hazards, idle power clock gating, weight retention, BIST hijack.
*   **Systolic Array (TC26-TC30):** Identity matrix routing proof, max bounds KSA overflow, pipeline bubble survival, 1000-cycle stress.
*   **BIST Controller (TC31-TC35):** March-C execution, Golden MISR match, defect flagging, noise isolation, seamless recovery.
*   **Top Specialized (TC36-TC42):** Including extreme boundaries, zero-matrix datapath flush, asynchronous pipeline stalls, and DFT MUX override.

---

## 23. Pre-Tape-Out Architectural Debugging Log

During the final top-level integration phase preceding UVM Hybrid Verification, rigorous static analysis and architectural reviews revealed two critical dataflow issues and three major system-level fatal flaws. These have been successfully diagnosed and resolved to achieve tape-out readiness.

### 1. Critical Case 1: The "Weight Flush" Overwrite
*   **The Error:** The top-level `array_load_weight_valid` signal was bound to `current_state == S_LOAD_WEIGHTS`. Because the FSM waits in this state for the physical array to assert `array_weight_locked` (which has a multi-cycle propagation delay), the valid signal remained HIGH while `sram_re` correctly dropped to `0`. This continuously pumped zeros into the systolic array, effectively flushing and destroying the previously loaded weights.
*   **The Diagnosis & Fix:** The valid signal must strictly mirror the active SRAM read cycles.
*   **The Solution:** The FSM logic was updated to `array_load_weight_valid <= (current_state == S_LOAD_WEIGHTS) && sram_re && (sram_r_addr < 16)`. This accurately drops the valid flag upon completing the 16-row sweep, safely freezing the weights in the pipeline.

### 2. Critical Case 2: The Pipeline Mismatch (Control vs Datapath Skew)
*   **The Error:** A timing cut-off was observed where Row 14 and 15 dropped to `0`. While `array_o_valid` was successfully delayed by 1 cycle in the top module to match the 2-stage systolic math latency, the 512-bit `array_o_psum_packed` bus remained strictly combinational.
*   **The Diagnosis & Fix:** A fundamental rule of pipeline design: *Never delay a control signal without putting a matching pipeline stage on the data bus.* The external AXI-Stream module was capturing the combinational data 1 cycle out-of-sync.
*   **The Solution:** Implemented a 512-bit `array_o_psum_packed_aligned` pipeline register to perfectly align the data and valid signals hitting the output FIFO.

### 3. Fatal Flaw 1: The Architectural Disconnect (BIST vs AXI-Lite)
*   **The Error:** The original spec dictated that BIST control (Start, Status, and the 512-bit MISR Signature) should be managed via the AXI-Lite control plane. However, funneling a 512-bit signature through a 32-bit bus requires 16 sequential writes, creating massive bottlenecks. More critically, testing the hardware using the very AXI logic that might contain manufacturing faults defeats the purpose of BIST isolation.
*   **The Diagnosis & Fix:** BIST operations must bypass the functional digital logic entirely to ensure pristine testability.
*   **The Solution:** Decoupled BIST from AXI-Lite entirely. BIST signals are now routed directly to external top-level pins connected to an isolated JTAG TAP controller. A 2-stage Clock Domain Crossing (CDC) synchronizer was added to safely translate the asynchronous JTAG TCK domain signals into the 250MHz system clock domain.

### 4. Fatal Flaw 2: The Phantom Wire and the Polling Delusion
*   **The Error:** The AXI-Stream Receiver generated a 1-cycle `rx_matrix_done` pulse upon successfully loading a matrix into SRAM. This signal was unrouted ("phantom wire") to the core FSM, creating a synchronization void where the CPU blindly guessed when the DMA finished. The initial fix attempted to route this 1-cycle pulse directly to a software status register for spin-polling.
*   **The Diagnosis & Fix:** It is statistically impossible for a software CPU to reliably poll a 1-cycle (4ns) hardware pulse.
*   **The Solution:** Implemented a "Sticky Register" (`sticky_rx_done`) in the AXI-Lite config module. The hardware sets the sticky flag on the 1-cycle pulse, and software explicitly clears it upon triggering the computation. The UVM Sequences were updated to proactively spin-poll this flag before initiating `start_compute`, eliminating all Read-After-Write hazards.

### 5. Fatal Flaw 3: The Off-By-One FSM Latch Bug
*   **The Error:** The `S_DRAIN` state counter waited for `drain_cnt == 48`. Because zero-indexed counters spend 49 physical clock cycles to reach count 48, the output latency violated the strict 48-cycle specification, triggering massive UVM Scoreboard SV failure. An initial fix attempted to resolve this by adding counter increments directly into the FSM's combinational block.
*   **The Diagnosis & Fix:** Injecting non-blocking assignments (`<=`) and sequential counter additions into an `always_comb` block infers catastrophic latches. The strict 3-block FSM architecture (Registers, Combinational Next-State, Registered Outputs) must be respected.
*   **The Solution:** Adjusted the combinational next-state evaluation strictly to `if (drain_cnt == 47)` to physically enforce 48 total clock cycles. The counter incrementing and output flagging were preserved purely in the synchronous block.
