module Sigmoid #(
    parameter sigmoid_max = 123
) (
    // SYSTEM I/O
    input clk,
    input reset,
    input  wire signed [31:0] x,
    output reg [31:0] o
);
// parameter, reg, wire
reg sign, sign1, sign2;
reg [31:0] x1, x2, x3;
reg [3:0] b_index;
reg [31:0] b [0:8];
// Sequential Logic
always @(posedge clk) begin
    if(reset) begin
        sign <= 0;
        sign1 <= 0;
        sign2 <= 0;
        x1 <= 0;
        x2 <= 0;
        x3 <= 0;
        b_index <= 0;
        b[0] <= 32'd937; // 0.5
        b[1] <= 32'd1186; // 0.6328125
        b[2] <= 32'd1435; // 0.765625
        b[3] <= 32'd1610; // 0.859375
        b[4] <= 32'd1720; // 0.91796875
        b[5] <= 32'd1786; // 0.951543
        b[6] <= 32'd1822; // 0.97265625
        b[7] <= 32'd1844; // 0.984375
        b[8] <= 32'd1874; // 1.0
        o <= 0;
    end
    else begin
            if(x<0) begin
                sign <= 1;
                x1 <= ~x;
            end
            else begin
                sign <= 0;
                x1 <= x;
            end
            sign1 <= sign;
            sign2 <= sign1;
            if(x1 >= 0 && x1 < 1996) begin
                x2 <= x1 >> 2; // x2 = mx1, m = 1/4
                b_index <= 0;
            end
            else if(x1 >= 1996 && x1 < 4055) begin
                x2 <= x1 >> 3; // x2 = mx1, m = 1/8
                b_index <= 1;
            end
            else if(x1 >= 4055 && x1 < 5578) begin
                x2 <= x1 >> 4; // x2 = mx1, m = 1/16
                b_index <= 2;
            end
            else if(x1 >= 5578 && x1 < 6978) begin
                x2 <= x1 >> 5; // x2 = mx1, m = 1/32
                b_index <= 3;
            end
            else if(x1 >= 6978 && x1 < 8323) begin
                x2 <= x1 >> 6; // x2 = mx1, m = 1/64
                b_index <= 4;
            end
            else if(x1 >= 8323 && x1 < 9644) begin
                x2 <= x1 >> 7; // x2 = mx1, m = 1/128
                b_index <= 5;
            end
            else if(x1 >= 9644 && x1 < 10954) begin
                x2 <= x1 >> 8; // x2 = mx1, m = 1/256
                b_index <= 6;
            end
            else if(x1 >= 10954 && x1 < 13558) begin
                x2 <= x1 >> 9; // x2 = mx1, m = 1/512
                b_index <= 7;
            end
            else begin
                x2 <= 0; // x2 = mx1, m = 0
                b_index <= 8;
            end
            x3 <= (x2 + b[b_index]);
            if(sign2) o <= (sigmoid_max - x3);
            else o <= x3;
    end
end
endmodule