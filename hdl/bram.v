`timescale 1ns / 1ps

module bram #(
    parameter RAM_WIDTH = 24,                  // Specify RAM data width
    parameter RAM_DEPTH = 8192                  // Specify RAM depth (number of entries)
)(
    wire [clogb2(RAM_DEPTH-1)-1:0] addra,
    wire [clogb2(RAM_DEPTH-1)-1:0] addrb,
    wire [RAM_WIDTH-1:0] dina,
    wire clka,
    wire wea,
    wire enb,
    wire [RAM_WIDTH-1:0] doutb
    );

  reg [RAM_WIDTH-1:0] ram [RAM_DEPTH-1:0];
  reg [RAM_WIDTH-1:0] ram_data = {RAM_WIDTH{1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          ram[ram_index] = {RAM_WIDTH{1'b0}};
    end
  endgenerate

  always @(posedge clka) begin
    if (wea)
      ram[addra] <= dina; 
    if (enb)
      ram_data <= ram[addrb];
  end        

  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
  generate
       assign doutb = ram_data;
  endgenerate

  //  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction 
endmodule
