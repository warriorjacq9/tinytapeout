/*
 * Copyright (c) 2025 Jack Flusche
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


module tt_um_warriorjacq9 ( /* verilator lint_off DECLFILENAME */
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  // Inputs
  wire [3:0] opcode;
  assign opcode = ui_in[3:0];
  
  wire [3:0] mio_in; // Memory/IO
  assign mio_in = ui_in[7:4];

  // Outputs
  reg [3:0] bus_req; // Request bus
  assign uo_out[3:0] = bus_req;

  reg [3:0] mio_out; // Memory/IO
  assign uo_out[7:4] = mio_out;
  
  // Bidirectional pins

  // Main bus
  reg [3:0] bus_out;
  assign uio_out[3:0] = bus_out;
  
  wire [3:0] bus_in;
  assign bus_in = uio_in[3:0];

  // Control signals
  wire oe_n;
  assign oe_n = uio_in[4];

  wire carry;
  assign uio_out[6] = carry;

  reg done;
  assign uio_out[7] = done;

  // I/O assignments

  // = 4b'1111 when outputting, 4b'0000 when inputting
  reg [3:0] bus_iomask;
  assign uio_oe[3:0] = bus_iomask;

  assign uio_oe[5:4] = 0; // Set Output Enable, Ready as input
  assign uio_oe[7:6] = 1; // Set Done, Carry as output

  reg [3:0] temp;

  reg [3:0] a;
  reg [3:0] b;
  reg [4:0] c;
  assign carry = c[4];
  reg [2:0] phase;
  initial {phase, a, b, c, bus_iomask, done, bus_out, bus_req, mio_out} = 0;
  always @(posedge clk) begin
    case (opcode)
      1: begin // ADDI
        case (phase)
          0: begin
            done <= 0;
            a <= mio_in;
            bus_req <= 4'b0011; // Request next operand (register number)
            phase <= 1;
          end
          1: begin
            bus_iomask <= 4'b1111;
            bus_req <= 4'b0001; // Receive register value
            phase <= 2;
          end
          2: begin
            b <= bus_in;
            bus_iomask <= 4'b0000;
            phase <= 3;
          end
          3: begin
            c <= a + b;
            phase <= 4;
          end
          4: begin
            bus_out <= c[3:0];
            done <= 1;
            phase <= 0;
          end
        endcase
      end
    endcase
  end


  // List all unused inputs to prevent warnings
  wire _unused = &{ena, rst_n, 1'b0};
endmodule
