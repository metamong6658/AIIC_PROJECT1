module accumulator (
    input i_clk,
    input i_accumulator_clr,
    input   wire signed  [31:0]  i_data,
    output  reg  signed  [31:0]  o_data
);
always @(posedge i_clk) begin
    if(i_accumulator_clr) begin
        o_data <= 0;
    end
    else begin
        o_data <= o_data + i_data;
    end
end
endmodule