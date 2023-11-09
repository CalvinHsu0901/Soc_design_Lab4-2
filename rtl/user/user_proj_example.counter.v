// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype wire
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
)
(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif
    // Global
    //--------------------------------------------------
    input                      wb_clk_i,
    input                      wb_rst_i,
    // Wishbone Slave ports (WB MI A)
    //--------------------------------------------------
    input                      wbs_stb_i,
    input                      wbs_cyc_i,
    input                      wbs_we_i,
    input   [3:0]              wbs_sel_i,
    input  [31:0]              wbs_dat_i,
    input  [31:0]              wbs_adr_i,
    output                     wbs_ack_o,
    output [31:0]              wbs_dat_o,
    // Logic Analyzer Signals
    //--------------------------------------------------
    input  [127:0]             la_data_in,
    output [127:0]             la_data_out,
    input  [127:0]             la_oenb,
    // IOs
    //--------------------------------------------------
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,
    // IRQ
    //--------------------------------------------------
    output [2:0] irq
);
    //================================================================
    // INTERNAL WIRES / REGS
    //================================================================
    wire [31:0] ram_o; 
    wire [31:0] wdata;
    wire en;
    wire [3:0] ram_we;
    wire wbs_ack_o;
    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;
    wire clk, rst;
    reg [3:0] counter;
    wire ram_en;
    wire fir_en;
    wire fir_we;
    wire fir_valid;
    wire [31:0] fir_dat_o;

    //================================================================
    // INSTANCES
    //================================================================
    // firmware ram
    bram user_bram (
        .CLK(clk),
        .WE0(ram_we),
        .EN0(ram_en),
        .Di0(wdata),
        .Do0(ram_o),
        .A0(wbs_adr_i)
    );
    // wb2axi
    wb2axi user_wb2axi (
        // Global
        .clk(clk),
        .rst(rst),
        // WB decoded
        .fir_en(fir_en),
        .fir_we(fir_we),
        .fir_addr(wbs_adr_i[11:0]),
        .fir_dat_i(wdata),
        .fir_valid(fir_valid),
        .fir_dat_o(fir_dat_o)
    );

    //================================================================
    // WB MI A
    //================================================================
    // WB input control
    assign en    = wbs_cyc_i & wbs_stb_i;
    assign wdata = wbs_dat_i;
    // WB output
    assign wbs_ack_o = (counter == 4'd12) | (fir_valid);
    assign wbs_dat_o = (decoded2bram)? ram_o : fir_dat_o;
    // WB addr decoded
    assign decoded2bram = (wbs_adr_i[31:24] == 8'h38);
    assign decoded2fir  = (wbs_adr_i[31:24] == 8'h30);

    //================================================================
    // user_bram
    //================================================================
    // counter
    always @(posedge clk) begin
        if (rst | (counter == 4'd12))
            counter <= 4'd1;
        else if ((en == 1'b1) & decoded2bram)  // ??ªæ??WB cyc??®æ????¯bram?????????
            counter <= counter + 1'b1;
        else
            counter <= 4'd1;
    end
    // firmware ram control
    assign ram_we = wbs_sel_i & { 4{wbs_we_i} } & { 4{wbs_cyc_i} };
    assign ram_en = en & decoded2bram;

    //================================================================
    // wb decoded to fir
    //================================================================
    assign fir_en = en & decoded2fir;
    assign fir_we = wbs_we_i & wbs_cyc_i & decoded2fir;

    //================================================================
    // IO (Unused)
    //================================================================
    assign io_out = wbs_dat_o;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    //================================================================
    // IRQ (Unused)
    //================================================================
    assign irq = 3'b000;

    //================================================================
    // LA (Unused)
    //================================================================
    assign la_data_out = {{(124){1'b0}}, counter};	
    // Assuming LA probes [65:64] are for controlling the seq_gcd clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64] : wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65] : wb_rst_i;


endmodule
