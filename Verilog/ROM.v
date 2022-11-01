module ROM #(
    parameter addr_max = 123,
    parameter addr_width = 123,
    parameter data_width = 123,
    parameter INFILE = ""
) (
    input i_clk,
    input [addr_width-1:0] i_addr,
    output reg [data_width-1:0] o_data
);
reg [data_width-1:0] rom [0:addr_max-1];

initial begin
    $readmemh(INFILE,rom);
end

always @(posedge i_clk) begin
   o_data <= rom[i_addr]; 
end

endmodule