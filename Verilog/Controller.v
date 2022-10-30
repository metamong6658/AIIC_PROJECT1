////////////////////////////////////////////////////////////////////////////////////////
// RTL Implementation of CNN(dogs or cats model).                                     //                          
// This module use onely one PE(Multiplier, Accumulator, ReLu, Sigmoid).              //                                                 
// In other words, It is memory based architecture.                                   //
// Memory based architecture gets small area, low power.                              //
// However, It's latency is very higher than other parallel architecture.             //
// 1 DECISION requires 7699393 CLK.                                                   //
// This architecture are useful if the data are off-line data.                        //
// on-line data(real-time data) require good latency.                                 //
// So, this module is not appropriate for on-line data.                               //                                
// Complex controller is designed by FSM.                                             //
// FSM is composed of 27 STATES.                                                      //        
// If you have any question or find my mistake, please contact metamong6658@gmail.com //                                                             
////////////////////////////////////////////////////////////////////////////////////////
module Controller #(
    parameter Qw = 142,
    parameter sigmoid_max = 1564,
    parameter TESTNUMBER = 1,
    parameter ROM0_ADDR_MAX = 3364,
    parameter ROM0_ADDR_WIDTH = 12,
    parameter INFILE0 = "RTL_test_data.hex",
    parameter INFILE1 = "weights_layer1.hex",
    parameter INFILE2 = "weights_layer2.hex",
    parameter INFILE3 = "weights_layer3.hex",
    parameter INFILE4 = "weights_layer4.hex"
) (
    input i_clk,
    input i_rst,
    input i_en,
    output reg [19:0] o_array, // 0 : cat, 1 : dog
    output reg done // 1 : done
);
///////////// FOR TEST /////////////
reg [4:0] numberOftest;
///////////// PARAMETER /////////////
localparam RAM1_ADDR_MAX = 12544;
localparam RAM1_ADDR_WIDTH = 14;
localparam RAM2_ADDR_MAX = 5408;
localparam RAM2_ADDR_WIDTH = 13;
localparam RAM3_ADDR_MAX = 64;
localparam RAM3_ADDR_WIDTH = 6;
localparam ROM1_ADDR_MAX = 144;
localparam ROM1_ADDR_WIDTH = 8;
localparam ROM2_ADDR_MAX = 288;
localparam ROM2_ADDR_WIDTH = 9;
localparam ROM3_ADDR_MAX = 346112;
localparam ROM3_ADDR_WIDTH = 19;
localparam ROM4_ADDR_MAX = 64;
localparam ROM4_ADDR_WIDTH = 6;
localparam DATA_WIDTH = 8;
///////////// REG, WIRE /////////////
// PE
reg [DATA_WIDTH-1:0] i_pe_data;
reg signed [DATA_WIDTH-1:0] i_pe_weight;
reg i_op_activation;
reg i_accumulator_clr;
reg i_no_rect_quantize;
wire [DATA_WIDTH-1:0] o_pe_data; 
wire o_decision;
// RAM
reg i_mem_clr;
reg i_ram1_op;
reg [RAM1_ADDR_WIDTH-1:0] i_ram1_addr;
reg [DATA_WIDTH-1:0] i_ram1_data;
wire [DATA_WIDTH-1:0] o_ram1_data;
reg i_ram2_op;
reg [RAM2_ADDR_WIDTH-1:0] i_ram2_addr;
reg [DATA_WIDTH-1:0] i_ram2_data;
wire [DATA_WIDTH-1:0] o_ram2_data;
reg i_ram3_op;
reg [RAM3_ADDR_WIDTH-1:0] i_ram3_addr;
reg [DATA_WIDTH-1:0] i_ram3_data;
wire [DATA_WIDTH-1:0] o_ram3_data;
// ROM
reg [ROM0_ADDR_WIDTH-1:0] i_rom0_addr;
wire [DATA_WIDTH-1:0] o_rom0_data; 
reg [ROM1_ADDR_WIDTH-1:0] i_rom1_addr;
wire [DATA_WIDTH-1:0] o_rom1_data; 
reg [ROM2_ADDR_WIDTH-1:0] i_rom2_addr;
wire [DATA_WIDTH-1:0] o_rom2_data;
reg [ROM3_ADDR_WIDTH-1:0] i_rom3_addr;
wire [DATA_WIDTH-1:0] o_rom3_data;
reg [ROM4_ADDR_WIDTH-1:0] i_rom4_addr;
wire [DATA_WIDTH-1:0] o_rom4_data;
// CONTROL FLAG
reg [5:0] row;
reg [5:0] col;
reg [1:0] cnt_row;
reg [1:0] cnt_col;
reg [RAM2_ADDR_WIDTH-1:0] cnt_accumulator;
reg [2:0] cnt_pe;
reg [ROM0_ADDR_WIDTH-1:0] ram_write_addr;
reg [3:0] cnt_image;
reg [RAM3_ADDR_WIDTH-1:0] cnt_ram3;
reg [4:0] addr_start;
reg [3:0] cnt_weight;
reg [ROM3_ADDR_WIDTH-1:0] cnt_rom3;
///////////// INTERNAL CONNECTION /////////////
PE #(Qw, sigmoid_max) i_PE(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_data(i_pe_data),
    .i_weight(i_pe_weight),
    .i_op_activation(i_op_activation),
    .i_accumulator_clr(i_accumulator_clr),
    .i_no_rect_quantize(i_no_rect_quantize),
    .o_data(o_pe_data),
    .o_decision(o_decision)
);
RAM #(RAM1_ADDR_MAX, RAM1_ADDR_WIDTH, DATA_WIDTH) i_RAM1(
    .i_clk(i_clk),
    .i_op(i_ram1_op),
    .i_addr(i_ram1_addr),
    .i_data(i_ram1_data),
    .i_mem_clr(i_mem_clr),
    .o_data(o_ram1_data)
);
RAM #(RAM2_ADDR_MAX, RAM2_ADDR_WIDTH, DATA_WIDTH) i_RAM2(
    .i_clk(i_clk),
    .i_op(i_ram2_op),
    .i_addr(i_ram2_addr),
    .i_data(i_ram2_data),
    .i_mem_clr(i_mem_clr),
    .o_data(o_ram2_data)
);
RAM #(RAM3_ADDR_MAX, RAM3_ADDR_WIDTH, DATA_WIDTH) i_RAM3(
    .i_clk(i_clk),
    .i_op(i_ram3_op),
    .i_addr(i_ram3_addr),
    .i_data(i_ram3_data),
    .i_mem_clr(i_mem_clr),
    .o_data(o_ram3_data)
);
ROM #(ROM0_ADDR_MAX, ROM0_ADDR_WIDTH, DATA_WIDTH, INFILE0) i_ROM0(
    .i_clk(i_clk),
    .i_addr(i_rom0_addr),
    .o_data(o_rom0_data)
); // TEST DATA ROM
ROM #(ROM1_ADDR_MAX, ROM1_ADDR_WIDTH, DATA_WIDTH, INFILE1) i_ROM1(
    .i_clk(i_clk),
    .i_addr(i_rom1_addr),
    .o_data(o_rom1_data)
); // WEIGHTS OF LAYER1
ROM #(ROM2_ADDR_MAX, ROM2_ADDR_WIDTH, DATA_WIDTH, INFILE2) i_ROM2(
    .i_clk(i_clk),
    .i_addr(i_rom2_addr),
    .o_data(o_rom2_data)
); // WEIGHTS OF LAYER2
ROM #(ROM3_ADDR_MAX, ROM3_ADDR_WIDTH, DATA_WIDTH, INFILE3) i_ROM3(
    .i_clk(i_clk),
    .i_addr(i_rom3_addr),
    .o_data(o_rom3_data)
); // WEIGHTS OF LAYER3
ROM #(ROM4_ADDR_MAX, ROM4_ADDR_WIDTH, DATA_WIDTH, INFILE4) i_ROM4(
    .i_clk(i_clk),
    .i_addr(i_rom4_addr),
    .o_data(o_rom4_data)
); // WEIGHTS OF LAYER4
///////////// STATE /////////////
reg [4:0] r_ps;
localparam ST_IDLE = 0;
localparam ST_LAYER1_INPUT_ADDR = 1;
localparam ST_LAYER1_READ = 2;
localparam ST_LAYER1_CALCULATE = 3;
localparam ST_LAYER1_HOLD = 4;
localparam ST_LAYER1_OUTPUT_ADDR = 5;
localparam ST_LAYER1_WRITE = 6;
localparam ST_LAYER2_INPUT_ADDR = 7;
localparam ST_LAYER2_READ = 8;
localparam ST_LAYER2_CALCULATE = 9;
localparam ST_LAYER2_HOLD = 10;
localparam ST_LAYER2_OUTPUT_ADDR = 11;
localparam ST_LAYER2_READ2 = 12;
localparam ST_LAYER2_HOLD2 = 13;
localparam ST_LAYER2_WRITE = 14;
localparam ST_LAYER3_INPUT_ADDR = 15;
localparam ST_LAYER3_READ = 16;
localparam ST_LAYER3_CALCULATE = 17;
localparam ST_LAYER3_HOLD = 18;
localparam ST_LAYER3_OUTPUT_ADDR = 19;
localparam ST_LAYER3_WRITE = 20;
localparam ST_LAYER4_INPUT_ADDR = 21;
localparam ST_LAYER4_READ = 22;
localparam ST_LAYER4_CALCULATE = 23;
localparam ST_LAYER4_HOLD = 24;
localparam ST_LAYER4_DECISION = 25;
localparam ST_DONE = 26;
///////////// FSM CONTROLLER /////////////
always @(posedge i_clk) begin
    if(i_rst) begin
        // FOR TEST
        numberOftest <= 0;
        // STATE
        r_ps <= ST_IDLE;
        // OUTPUT
        o_array <= 0;
        done <= 0;
        // PE
        i_pe_data <= 0;
        i_pe_weight <= 0;
        i_op_activation <= 0;
        i_accumulator_clr <= 1;
        i_no_rect_quantize <= 0;
        // ROM0
        i_rom0_addr <= 0;
        // RAM1
        i_mem_clr <= 1;
        i_ram1_op <= 0;
        i_ram1_addr <= 0;
        i_ram1_data <= 0;
        // RAM2
        i_ram2_op <= 0;
        i_ram2_addr <= 0;
        i_ram2_data <= 0;
        // RAM3
        i_ram3_op <= 0;
        i_ram3_addr <= 0;
        i_ram3_data <= 0;
        // ROM1
        i_rom1_addr <= 0;
        // ROM2
        i_rom2_addr <= 0;
        // ROM3
        i_rom3_addr <= 0;
        // ROM4
        i_rom4_addr <= 0;
        // CONTROL FLAG
        row <= 0;
        col <= 0;
        cnt_row <= 0;
        cnt_col <= 0;
        cnt_accumulator <= 0;
        cnt_pe <= 0;
        ram_write_addr <= 0;
        addr_start <= 0;
        cnt_weight <= 0;
        cnt_image <= 0;
        cnt_rom3 <= 0;
        cnt_ram3 <= 0;
    end
    else begin
        case (r_ps)
           ST_IDLE : 
           begin
            if(i_en) begin
                r_ps <= ST_LAYER1_INPUT_ADDR;
                i_accumulator_clr <= 1;
                i_mem_clr <= 1;
            end
           end
           ST_LAYER1_INPUT_ADDR : 
           begin
            r_ps <= ST_LAYER1_READ;
            i_accumulator_clr <= 0;
            i_mem_clr <= 0;
            // ROM1
            i_rom1_addr <= 9 * addr_start + cnt_weight;
            if(cnt_weight == 8) begin
                cnt_weight <= 0;
            end
            else begin
                cnt_weight <= cnt_weight + 1;
            end
            // ROM0
            i_rom0_addr <= (ROM0_ADDR_MAX / TESTNUMBER) * numberOftest + 58 * row + col;
            if(cnt_col == 2) begin
                cnt_col <= 0;
                if(cnt_row == 2) begin
                    cnt_row <= 0;
                    if(col == 56) begin
                        row <= row;
                        col <= 0;
                    end
                    else begin
                        row <= row - 2;
                        col <= col;                        
                    end
                end
                else begin
                    cnt_row <= cnt_row + 1;
                    row <= row + 1;
                    col <= col - 2;
                end
            end
            else begin
                cnt_col <= cnt_col + 1;
                col <= col + 1;
            end
           end
           ST_LAYER1_READ :
           begin
            r_ps <= ST_LAYER1_CALCULATE;
           end
           ST_LAYER1_CALCULATE :
           begin
            r_ps <= ST_LAYER1_HOLD;
            i_pe_data <= o_rom0_data;
            i_pe_weight <= o_rom1_data;
            i_op_activation <= 0;
           end
           ST_LAYER1_HOLD :
           begin
            i_pe_data <= 0;
            i_pe_weight <= 0;
            if(cnt_pe == 1) begin
                r_ps <= ST_LAYER1_OUTPUT_ADDR;
                cnt_pe <= 0;
            end
            else begin
                cnt_pe <= cnt_pe + 1;
            end
           end
           ST_LAYER1_OUTPUT_ADDR :
           begin
            if(cnt_accumulator == 8) begin
                r_ps <= ST_LAYER1_WRITE;
                i_ram1_op <= 1;
                i_ram1_data <= o_pe_data;
                i_ram1_addr <= 784 * addr_start + ram_write_addr;
                i_accumulator_clr <= 1;
                cnt_accumulator <= 0;
            end
            else begin
                r_ps <= ST_LAYER1_INPUT_ADDR;
                cnt_accumulator <= cnt_accumulator + 1;
            end
           end
           ST_LAYER1_WRITE :
           begin
            i_ram1_op <= 0;
            i_accumulator_clr <= 0;
            if(ram_write_addr == 783) begin
                row <= 0;
                col <= 0;
                cnt_row <= 0;
                cnt_col <= 0;
                cnt_pe <= 0;
                cnt_accumulator <= 0;
                cnt_weight <= 0;
                ram_write_addr <= 0;

                if(addr_start == 15) begin
                    r_ps <= ST_LAYER2_INPUT_ADDR;
                    addr_start <= 0;
                    i_rom1_addr <= 0;
                    i_rom0_addr <= 0;
                    i_ram1_addr <= 0;
                end
                else begin
                    r_ps <= ST_LAYER1_INPUT_ADDR;
                    addr_start <= addr_start + 1;
                end
            end
            else begin
                r_ps <= ST_LAYER1_INPUT_ADDR;
                ram_write_addr <= ram_write_addr + 1;
            end
           end
           ST_LAYER2_INPUT_ADDR :
           begin
            // ROM
            i_rom2_addr <= 9 * addr_start + cnt_weight;
            if(cnt_weight == 8) begin
                cnt_weight <= 0;
            end
            else begin
                cnt_weight <= cnt_weight + 1;
            end
            // RAM
            r_ps <= ST_LAYER2_READ;
            i_ram1_op <= 0;
            i_ram1_addr <= 169 * cnt_image + 28 * row + col;
            if(cnt_col == 2) begin
                cnt_col <= 0;
                if(cnt_row == 2) begin
                    cnt_row <= 0;
                    if(col == 26) begin
                        row <= row;
                        col <= 0;
                    end
                    else begin
                        row <= row - 2;
                        col <= col;
                    end
                end
                else begin
                    cnt_row <= cnt_row + 1;
                    row <= row + 1;
                    col <= col - 2;
                end
            end
            else begin
                cnt_col <= cnt_col + 1;
                col <= col + 1;
            end
           end 
           ST_LAYER2_READ :
           begin
            r_ps <= ST_LAYER2_CALCULATE;
           end
           ST_LAYER2_CALCULATE :
           begin
            r_ps <= ST_LAYER2_HOLD;
            i_pe_data <= o_ram1_data;
            i_pe_weight <= o_rom2_data;
            i_op_activation <= 0;
           end
           ST_LAYER2_HOLD :
           begin
            i_pe_data <= 0;
            i_pe_weight <= 0;
            if(cnt_pe == 1) begin
                r_ps <= ST_LAYER2_OUTPUT_ADDR;
                cnt_pe <= 0;
            end
            else begin
                cnt_pe <= cnt_pe + 1;
            end
           end
           ST_LAYER2_OUTPUT_ADDR :
           begin
            if(cnt_accumulator == 8) begin
                r_ps <= ST_LAYER2_READ2;
                cnt_accumulator <= 0;
                i_ram2_addr <= 169 * addr_start + ram_write_addr;
            end
            else begin
                r_ps <= ST_LAYER2_INPUT_ADDR;
                cnt_accumulator <= cnt_accumulator + 1;
            end
           end
           ST_LAYER2_READ2 :
           begin
            r_ps <= ST_LAYER2_HOLD2;
            if(cnt_image == 15) begin
                i_no_rect_quantize <= 0;
            end
            else begin
                i_no_rect_quantize <= 1;
            end
           end
           ST_LAYER2_HOLD2 :
           begin
            i_ram2_op <= 1;
            i_ram2_data <= o_ram2_data + o_pe_data;
            i_accumulator_clr <= 1;
            r_ps <= ST_LAYER2_WRITE;
           end
           ST_LAYER2_WRITE :
           begin
            i_ram2_op <= 0;
            i_accumulator_clr <= 0;
            if(ram_write_addr == 168) begin
                row <= 0;
                col <= 0;
                cnt_row <= 0;
                cnt_col <= 0;
                cnt_pe <= 0;
                cnt_accumulator <= 0;
                cnt_weight <= 0;
                ram_write_addr <= 0;
                if(addr_start == 31) begin
                    addr_start <= 0;
                    if (cnt_image == 15) begin
                        r_ps <= ST_LAYER3_INPUT_ADDR;
                        i_rom2_addr <= 0;
                        i_ram1_addr <= 0;
                        i_ram2_addr <= 0;
                        cnt_image <= 0;
                    end
                    else begin
                        r_ps <= ST_LAYER2_INPUT_ADDR;
                        cnt_image <= cnt_image + 1;
                    end
                end
                else begin
                    r_ps <= ST_LAYER2_INPUT_ADDR;
                    addr_start <= addr_start + 1;
                end
            end
            else begin
                r_ps <= ST_LAYER2_INPUT_ADDR;
                ram_write_addr <= ram_write_addr + 1;
            end
           end
           ST_LAYER3_INPUT_ADDR :
           begin
            r_ps <= ST_LAYER3_READ;
            // ROM
            i_rom3_addr <= cnt_rom3;
            if(cnt_rom3 == ROM3_ADDR_MAX-1) begin
                cnt_rom3 <= 0;
            end
            else begin
                cnt_rom3 <= cnt_rom3 + 1;
            end
            // RAM
            i_ram2_op <= 0;
            i_ram2_addr <= cnt_accumulator;
           end
           ST_LAYER3_READ :
           begin
            r_ps <= ST_LAYER3_CALCULATE;
           end
           ST_LAYER3_CALCULATE :
           begin
            r_ps <= ST_LAYER3_HOLD;
            i_pe_data <= o_ram2_data;
            i_pe_weight <= o_rom3_data;
            i_op_activation <= 0;
           end
           ST_LAYER3_HOLD:
           begin
            i_pe_data <= 0;
            i_pe_weight <= 0;
            if(cnt_pe == 1) begin
                r_ps <= ST_LAYER3_OUTPUT_ADDR;
                cnt_pe <= 0;
            end
            else begin
                cnt_pe <= cnt_pe + 1;
            end
           end
           ST_LAYER3_OUTPUT_ADDR :
           begin
            if(cnt_accumulator == RAM2_ADDR_MAX-1) begin
                r_ps <= ST_LAYER3_WRITE;
                cnt_accumulator <= 0;
                i_ram3_op <= 1;
                i_ram3_addr <= cnt_ram3;
                i_ram3_data <= o_pe_data;
                i_accumulator_clr <= 1;
            end
            else begin
                r_ps <= ST_LAYER3_INPUT_ADDR;
                cnt_accumulator <= cnt_accumulator + 1;
            end
           end
           ST_LAYER3_WRITE :
           begin
            i_ram3_op <= 0;
            i_accumulator_clr <= 0;
            if(cnt_ram3 == RAM3_ADDR_MAX -1) begin
                r_ps <= ST_LAYER4_INPUT_ADDR;
                cnt_ram3 <= 0;
                i_rom3_addr <= 0;
                i_ram2_addr <= 0;
                i_ram3_addr <= 0;
            end
            else begin
                r_ps <= ST_LAYER3_INPUT_ADDR;
                cnt_ram3 <= cnt_ram3 + 1;
            end
           end
           ST_LAYER4_INPUT_ADDR :
           begin
            r_ps <= ST_LAYER4_READ;
            i_ram3_op <= 0;
            i_ram3_addr <= cnt_ram3;
            i_rom4_addr <= cnt_ram3;
           end
           ST_LAYER4_READ :
           begin
            r_ps <= ST_LAYER4_CALCULATE;
           end
           ST_LAYER4_CALCULATE :
           begin
            r_ps <= ST_LAYER4_HOLD;
            i_pe_data <= o_ram3_data;
            i_pe_weight <= o_rom4_data;
            i_op_activation <= 1;
           end
           ST_LAYER4_HOLD :
           begin
            i_pe_data <= 0;
            i_pe_weight <= 0;
            if(cnt_pe == 5) begin
                r_ps <= ST_LAYER4_DECISION;
                cnt_pe <= 0;
            end
            else begin
                cnt_pe <= cnt_pe + 1;
            end
           end
           ST_LAYER4_DECISION :
           begin
            if(cnt_ram3 == RAM3_ADDR_MAX-1) begin
                r_ps <= ST_DONE;
                o_array[0] <= o_decision;
                o_array[9:1] <= o_array[8:0];
                done <= 1;
                cnt_ram3 <= 0;
                i_ram3_addr <= 0;
                i_rom4_addr <= 0;
                i_op_activation <= 0;
                i_accumulator_clr <= 1;
            end
            else begin
                r_ps <= ST_LAYER4_INPUT_ADDR;
                cnt_ram3 <= cnt_ram3 + 1;
            end
           end
           ST_DONE : begin
            // FOR TEST
            if(numberOftest == TESTNUMBER -1) begin
                numberOftest <= 0;
                r_ps <= ST_DONE;
            end
            else begin
                numberOftest <= numberOftest + 1;
                r_ps <= ST_IDLE;
            end
            done <= 0;
            i_pe_data <= 0;
            i_pe_weight <= 0;
            i_op_activation <= 0;
            i_accumulator_clr <= 0;
            i_no_rect_quantize <= 0;
            i_rom0_addr <= 0;
            i_ram1_op <= 0;
            i_ram1_addr <= 0;
            i_ram1_data <= 0;
            i_ram2_op <= 0;
            i_ram2_addr <= 0;
            i_ram2_data <= 0;
            i_ram3_op <= 0;
            i_ram3_addr <= 0;
            i_ram3_data <= 0;
            i_rom1_addr <= 0;
            i_rom2_addr <= 0;
            i_rom3_addr <= 0;
            i_rom4_addr <= 0;
            row <= 0;
            col <= 0;
            cnt_row <= 0;
            cnt_col <= 0;
            cnt_accumulator <= 0;
            cnt_pe <= 0;
            ram_write_addr <= 0;
            addr_start <= 0;
            cnt_weight <= 0;
            cnt_image <= 0;
            cnt_rom3 <= 0;
            cnt_ram3 <= 0;
           end
        endcase
    end
end
endmodule