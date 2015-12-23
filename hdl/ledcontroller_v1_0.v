
`timescale 1 ns / 1 ps

	module ledcontroller_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_ID_WIDTH	= 1,
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 16,
		parameter integer C_S00_AXI_AWUSER_WIDTH	= 0,
		parameter integer C_S00_AXI_ARUSER_WIDTH	= 0,
		parameter integer C_S00_AXI_WUSER_WIDTH	= 0,
		parameter integer C_S00_AXI_RUSER_WIDTH	= 0,
		parameter integer C_S00_AXI_BUSER_WIDTH	= 0
	)
	(
		// Users to add ports here
        input wire core_clk,
        input wire core_rst,
        output wire LED_CK,
        output wire LED_STB,
        output wire LED_OE,
        output wire [3:0] LED_BANK,
        output wire [7:0] LED_R,
        output wire [7:0] LED_G,
        output wire [7:0] LED_B,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ID_WIDTH-1 : 0] s00_axi_awid,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [7 : 0] s00_axi_awlen,
		input wire [2 : 0] s00_axi_awsize,
		input wire [1 : 0] s00_axi_awburst,
		input wire  s00_axi_awlock,
		input wire [3 : 0] s00_axi_awcache,
		input wire [2 : 0] s00_axi_awprot,
		input wire [3 : 0] s00_axi_awqos,
		input wire [3 : 0] s00_axi_awregion,
		input wire [C_S00_AXI_AWUSER_WIDTH-1 : 0] s00_axi_awuser,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wlast,
		input wire [C_S00_AXI_WUSER_WIDTH-1 : 0] s00_axi_wuser,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [C_S00_AXI_ID_WIDTH-1 : 0] s00_axi_bid,
		output wire [1 : 0] s00_axi_bresp,
		output wire [C_S00_AXI_BUSER_WIDTH-1 : 0] s00_axi_buser,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ID_WIDTH-1 : 0] s00_axi_arid,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [7 : 0] s00_axi_arlen,
		input wire [2 : 0] s00_axi_arsize,
		input wire [1 : 0] s00_axi_arburst,
		input wire  s00_axi_arlock,
		input wire [3 : 0] s00_axi_arcache,
		input wire [2 : 0] s00_axi_arprot,
		input wire [3 : 0] s00_axi_arqos,
		input wire [3 : 0] s00_axi_arregion,
		input wire [C_S00_AXI_ARUSER_WIDTH-1 : 0] s00_axi_aruser,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_ID_WIDTH-1 : 0] s00_axi_rid,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rlast,
		output wire [C_S00_AXI_RUSER_WIDTH-1 : 0] s00_axi_ruser,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
    (* mark_debug = "true" *) wire [C_S00_AXI_ADDR_WIDTH-1 : 0] mem_address;
    wire mem_wren;
    wire mem_rden;
    wire [23:0] mem_rdata;
// Instantiation of Axi Bus Interface S00_AXI
	ledcontroller_v1_0_S00_AXI # ( 
		.C_S_AXI_ID_WIDTH(C_S00_AXI_ID_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
		.C_S_AXI_AWUSER_WIDTH(C_S00_AXI_AWUSER_WIDTH),
		.C_S_AXI_ARUSER_WIDTH(C_S00_AXI_ARUSER_WIDTH),
		.C_S_AXI_WUSER_WIDTH(C_S00_AXI_WUSER_WIDTH),
		.C_S_AXI_RUSER_WIDTH(C_S00_AXI_RUSER_WIDTH),
		.C_S_AXI_BUSER_WIDTH(C_S00_AXI_BUSER_WIDTH)
	) ledcontroller_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWID(s00_axi_awid),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWLEN(s00_axi_awlen),
		.S_AXI_AWSIZE(s00_axi_awsize),
		.S_AXI_AWBURST(s00_axi_awburst),
		.S_AXI_AWLOCK(s00_axi_awlock),
		.S_AXI_AWCACHE(s00_axi_awcache),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWQOS(s00_axi_awqos),
		.S_AXI_AWREGION(s00_axi_awregion),
		.S_AXI_AWUSER(s00_axi_awuser),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WLAST(s00_axi_wlast),
		.S_AXI_WUSER(s00_axi_wuser),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BID(s00_axi_bid),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BUSER(s00_axi_buser),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARID(s00_axi_arid),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARLEN(s00_axi_arlen),
		.S_AXI_ARSIZE(s00_axi_arsize),
		.S_AXI_ARBURST(s00_axi_arburst),
		.S_AXI_ARLOCK(s00_axi_arlock),
		.S_AXI_ARCACHE(s00_axi_arcache),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARQOS(s00_axi_arqos),
		.S_AXI_ARREGION(s00_axi_arregion),
		.S_AXI_ARUSER(s00_axi_aruser),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RID(s00_axi_rid),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RLAST(s00_axi_rlast),
		.S_AXI_RUSER(s00_axi_ruser),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
        .mem_wren(mem_wren),
        .mem_rden(mem_rden),
        .mem_address(mem_address),
        .mem_rdata(mem_rdata)
	);

	// Add user logic here
    reg write_frame_sel;
   
    // Current writing address decoder
    wire [2:0] write_block = mem_address >> 13;
    
    // Data draw from framebuffer
    wire [6:0] draw_x;
    wire [3:0] draw_y;
    wire [3:0] draw_bit;
    wire draw_vsync;
        
    wire [15:0] current_reader_address = ((draw_y) << 7) + draw_x;
    
    // Block RAM access lines
    wire [7:0] frame_a_wen;
    wire [7:0] frame_b_wen;
    wire [23:0] reader_data [0:7];
    wire [23:0] reader_data_frame_a [0:7];
    wire [23:0] reader_data_frame_b [0:7];
    wire [23:0] mem_rdata_a;
    wire [23:0] mem_rdata_b;
    //wire frame_a_en = (write_frame_sel == 1);
    //wire frame_b_en = (write_frame_sel == 0);
    wire frame_a_en = 1;
    wire frame_b_en = 1;
    
    wire [7:0] reader_data_r [0:7];
    wire [7:0] reader_data_g [0:7];
    wire [7:0] reader_data_b [0:7];
    
    wire [11:0] gamma_r [0:7];
    wire [11:0] gamma_g [0:7];
    wire [11:0] gamma_b [0:7];

    wire [10:0] address = mem_address >> 2;
    
    //assign mem_rdata = 1rame_a_en ? reader_data_frame_b[write_block] : reader_data_frame_a[write_block];
    assign mem_rdata = reader_data_frame_b[write_block];
    genvar i;
    generate
        for (i = 0; i < 8; i=i+1) begin : BLOCKS
            //assign frame_a_wen[i] = (write_frame_sel == 0) && (write_block == i) && mem_wren;
            //assign frame_b_wen[i] = (write_frame_sel == 1) && (write_block == i) && mem_wren;
            assign frame_a_wen[i] = (write_block == i) && mem_wren;
            assign frame_b_wen[i] = (write_block == i) && mem_wren;
            //assign reader_data[i] = frame_a_en ? reader_data_frame_a[i] : reader_data_frame_b[i];
            assign reader_data[i] = reader_data_frame_a[i];
            wire [23:0] din = s00_axi_wdata;
            //wire [15:0] read_address_a = frame_a_en ? current_reader_address : address;
            //wire [15:0] read_address_b = frame_b_en ? current_reader_address : address;
            wire [15:0] read_address_a = current_reader_address;
            wire [15:0] read_address_b = address;
            //wire [23:0] din = 23'hFFFF00;
            bram #(
                .RAM_DEPTH(2048)
            ) ram_a (
                .clka(s00_axi_aclk),
                .addra(address),
                .wea(frame_a_wen[i]),
                .dina(din),
                .addrb(read_address_a),
                .enb(frame_a_en),
                .doutb(reader_data_frame_a[i])
            );
            bram #(
                .RAM_DEPTH(2048)
            ) ram_b (
                .clka(s00_axi_aclk),
                .addra(address),
                .wea(frame_b_wen[i]),
                .dina(din),
                .addrb(read_address_b),
                .enb(frame_b_en),
                .doutb(reader_data_frame_b[i])
            );
    
            assign reader_data_r[i] = reader_data[i][23:16];
            assign reader_data_g[i] = reader_data[i][15:8];
            assign reader_data_b[i] = reader_data[i][7:0];
    
            gamma g_r (
                .in(reader_data_r[i]),
                .out(gamma_r[i])
            );
            gamma g_g (
                .in(reader_data_g[i]),
                .out(gamma_g[i])
            );
            gamma g_b (
                .in(reader_data_b[i]),
                .out(gamma_b[i])
            );
    
            assign LED_R[i] = gamma_r[i] >> draw_bit;
            assign LED_G[i] = gamma_g[i] >> draw_bit;
            assign LED_B[i] = gamma_b[i] >> draw_bit;
        end
    endgenerate
    
      
    reg [1:0] vsync_twostep;
    reg [13:0] vsync_counter;
    always @(posedge core_clk) begin
       vsync_twostep <= {vsync_twostep[0], draw_vsync};
    end
    
    wire core_nrst = !core_rst;
    always @(posedge s00_axi_aclk or negedge core_nrst) begin
        if (!core_nrst) begin
            write_frame_sel <= 0;
            vsync_counter <= 0;
        end else begin
            if (vsync_twostep == 2'b10) begin
                if (vsync_counter >= 6000) begin
                    //write_frame_sel <= write_frame_sel ^ 1;
                    vsync_counter <= 0;
                end else begin
                    vsync_counter <= vsync_counter + 1;
                end
            end else begin
                vsync_counter <= vsync_counter + 1;
            end
        end
    end
    
    wire sys_en = 1;
    timing_generator tg (
        .sys_en(sys_en),
        .sys_clk(core_clk),
        .sys_rst(!core_rst),
        
        .led_clk(LED_CK),
        .led_stb(LED_STB),
        .led_oe(LED_OE),
        .led_bank(LED_BANK),
        
        .ctl_cur_x(draw_x),
        .ctl_cur_y(draw_y),
        .ctl_cur_bit(draw_bit),
        .ctl_vsync(draw_vsync)
    );

	// User logic ends

	endmodule
