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
        b[0] <= 32'd936; // 0.5
        b[1] <= 32'd1185; // 0.6328125
        b[2] <= 32'd1434; // 0.765625
        b[3] <= 32'd1609; // 0.859375
        b[4] <= 32'd1719; // 0.91796875
        b[5] <= 32'd1785; // 0.951543
        b[6] <= 32'd1821; // 0.97265625
        b[7] <= 32'd1843; // 0.984375
        b[8] <= 32'd1872; // 1.0
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
            if(x1 >= 0 && x1 < 1994) begin
                x2 <= x1 >> 2; // x2 = mx1, m = 1/4
                b_index <= 0;
            end
            else if(x1 >= 1994 && x1 < 4052) begin
                x2 <= x1 >> 3; // x2 = mx1, m = 1/8
                b_index <= 1;
            end
            else if(x1 >= 4052 && x1 < 5574) begin
                x2 <= x1 >> 4; // x2 = mx1, m = 1/16
                b_index <= 2;
            end
            else if(x1 >= 5574 && x1 < 6973) begin
                x2 <= x1 >> 5; // x2 = mx1, m = 1/32
                b_index <= 3;
            end
            else if(x1 >= 6973 && x1 < 8317) begin
                x2 <= x1 >> 6; // x2 = mx1, m = 1/64
                b_index <= 4;
            end
            else if(x1 >= 8317 && x1 < 9637) begin
                x2 <= x1 >> 7; // x2 = mx1, m = 1/128
                b_index <= 5;
            end
            else if(x1 >= 9637 && x1 < 10946) begin
                x2 <= x1 >> 8; // x2 = mx1, m = 1/256
                b_index <= 6;
            end
            else if(x1 >= 10946 && x1 < 13549) begin
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