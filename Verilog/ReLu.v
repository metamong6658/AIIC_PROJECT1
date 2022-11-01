module ReLu(r_in,r_out);
// port
input  wire signed [31:0] r_in;
output reg [31:0] r_out;

// Combinational Logic
always @(*) begin
    if(r_in<0) r_out <= 0;
    else r_out <= r_in;
end
endmodule