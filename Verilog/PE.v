module PE #(
    parameter Qw = 123,
    parameter sigmoid_max = 123)
(
    input i_clk,
    input i_rst,
    input signed [7:0] i_data,
    input signed [7:0] i_weight,
    input i_op_activation,  // 0 : ReLu, 1 : Sigmoid
    input i_accumulator_clr,
    input i_no_rect_quantize,
    output reg [7:0] o_data,
    output reg o_decision
);
///////////////// Multiplier /////////////////
reg signed [31:0] r_multi;
always @(*) begin
    r_multi <= i_data * i_weight;
end
///////////////// Accumulator /////////////////
// Accumulator : 1 clk delay
wire signed [31:0] w_acc;
accumulator i_accumulator(
    .i_clk(i_clk),
    .i_accumulator_clr(i_accumulator_clr),
    .i_data(r_multi),
    .o_data(w_acc)
);
///////////////// Activation /////////////////
// ReLu : no delay, it's combinational logic
wire [31:0] w_relu;
ReLu i_relu(
    .r_in(w_acc),
    .r_out(w_relu)
);
// Sigmoid : 4 clk delay, it's pipelined sequential logic
wire [31:0] w_sigmoid;
Sigmoid #(sigmoid_max) i_sigmoid(
    .clk(i_clk),
    .reset(i_rst),
    .x(w_acc),
    .o(w_sigmoid)
);
///////////////// Select activation /////////////////
reg [31:0] r_sel_act;
always @(*) begin
    if(i_op_activation) begin
        r_sel_act <= w_sigmoid;
    end
    else begin
        r_sel_act <= w_relu;
    end
end
///////////////// Select output /////////////////
always @(*) begin
    if(i_no_rect_quantize) begin
        o_data <= w_acc;
    end
    else begin
        o_data <= r_sel_act / Qw;
    end
end
///////////////// decision /////////////////
always @(*) begin
    if(o_data >= sigmoid_max / Qw / 2) o_decision <= 1;
    else o_decision <= 0;
end
endmodule