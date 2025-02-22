`default_nettype none
`timescale 1ns / 1ps

`define assert(signal, value) \
        if (signal !== value) begin \
            $error("\n%c[1;91mTEST FAILED in %m: signal != value%c[0m",27,27); \
            $finish; \
        end

module tb();
  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

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

  initial begin // Stimulate device
    ui_in = 8'b00100001; // ADDI 2
    #10; // Wait 5 clock cycles
    `assert (uio_out[3:0], 6);
    ui_in = 8'b00110001; // ADDI 3
    #10;
    `assert(uio_out[3:0], 7);
    ui_in = 8'b00000000;
    $display("%c[1;32mAll tests passed%c[0m", 27, 27);
    $finish;
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
