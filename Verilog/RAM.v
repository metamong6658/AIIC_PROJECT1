module RAM #(
    parameter addr_max = 123,
    parameter addr_width = 123,
    parameter data_width = 123
) (
    input i_clk,
    input i_op, // , 0 : read mode, 1 : write mode
    input [addr_width-1:0] i_addr,
    input [data_width-1:0] i_data,
    input i_mem_clr,
    output reg [data_width-1:0] o_data
);
integer I;
reg [data_width-1:0] ram [0:addr_max-1];

always @(posedge i_clk) begin
    if(i_mem_clr) begin
        for(I=0;I<addr_max;I=I+1) begin
            ram[I] = 0;
        end    
    end
    else begin
        if(i_op) begin
            ram[i_addr] <= i_data;
        end
        else begin
            o_data <= ram[i_addr];
        end
    end
end
endmodule