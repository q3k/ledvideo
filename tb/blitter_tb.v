`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2015 06:38:13 PM
// Design Name: 
// Module Name: blitter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module blitter_tb();

reg clk, rst;
wire fake_axi = 0;

ledvideo_v1_0 lv(
    .core_clk(clk),
    .core_rst(rst),
    
    .s00_axis_aclk(fake_axi),
    .s00_axis_aresetn(fake_axi),
    .s00_axis_tdata(fake_axi),
    .s00_axis_tstrb(fake_axi),
    .s00_axis_tlast(fake_axi),
    .s00_axis_tvalid(fake_axi)
);

initial begin
    clk = 0;
    rst = 1;
    
    // pulse once
    #10 clk = !clk;
    #10 clk = !clk;
    // bring out of reset
    rst = 0;
    // pulse again
    #10 clk = !clk;
    #10 clk = !clk;
end

always begin
    #5 clk = !clk;
end

endmodule
