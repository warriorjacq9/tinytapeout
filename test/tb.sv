`default_nettype none
`timescale 1ns / 1ps

`define assert(signal, value, fail_count, num, test_time) \
        if (signal !== value) begin \
          temp = signal; \
          $display("not ok %0d - signal !== value # time=%0.3f ms", num, test_time); \
          fail_count++; \
        end else begin \
          $display("ok %0d - signal == value # time=%0.3f ms", num, test_time); \
        end

module tb();
  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  logic temp;
  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_warriorjacq9 dut (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );
  int fail_count = 0;
  real start, end_time, test_time;
  initial begin // Stimulate device
    $display("TAP version 13");
    $display("1..2",); // 2 tests
    start = $realtime;
    #2;
    rst_n = 0;
    #2;
    rst_n = 1;
    ui_in = 8'b00100001; // ADDI 2
    #10; // Wait 5 clock cycles
    `assert (uio_out[3:0], 6, fail_count, 1, ($realtime - start) * 1e-3);
    test_time = $realtime;
    ui_in = 8'b00110001; // ADDI 3
    #10;
    `assert(uio_out[3:0], 7, fail_count, 2, ($realtime - test_time) * 1e-3);
    ui_in = 8'b00000000;

    end_time = $realtime;
    $display("# Total time: %0.3f ms", (end_time - start) * 1e-3);
    // Print results
    if (fail_count > 0) begin
      $display("# %0d test(s) failed", fail_count);
    end else begin
      $display("# All tests passed!");
    end
    $finish(0);
  end
  always @(uo_out[3:0]) begin // Listen for BUSREQ
    case(uo_out[3:0])
      4'b0011: begin // Next operand (Arbitrary for now, device can have up to 16 registers)
        ui_in[7:4] = 1; // Simulate next operand being register 1
      end
      4'b0001: begin  // Send a register value (On a real device, the register block will take the number in current memory location
        uio_in = 4;   // and give that register value to the ALU)
      end
    endcase
  end

  initial clk = 1;
  always #1 clk = ~clk;

endmodule