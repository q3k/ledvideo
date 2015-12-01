
`timescale 1 ns / 1 ps

	module ledvideo_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here
        input wire core_clk,
        input wire core_rst,
        
        output wire LED_CK,
        output wire LED_STB,
        output wire LED_OE,
        output wire [3:0] LED_BANK,
        output wire LED_R0,
        output wire LED_R1,
        output wire LED_G0,
        output wire LED_G1,
        output wire LED_B0,
        output wire LED_B1,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
	   input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid
	);
// Instantiation of Axi Bus Interface S00_AXIS
	ledvideo_v1_0_S00_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
	) ledvideo_v1_0_S00_AXIS_inst (
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid)
	); 


	reg write_frame_sel;
	
	// fake data provider
	reg [13:0] writer_pixel;
	wire [6:0] writer_y = writer_pixel >> 7;
	wire [6:0] writer_x = writer_pixel[6:0];
	
	//wire [7:0] writer_r = (writer_x == 0) ? 255 : 0;
	//wire [7:0] writer_g = (writer_y == 0) ? 255 : 0;
	//wire [7:0] writer_b = (writer_x == 127) ? 255 : 0;
	wire [7:0] writer_b = writer_x ^ writer_y;
	wire [7:0] writer_r = 0;
    wire [7:0] writer_g = 0;
	
	// magical Y draw split of magic... TODO(q3k): document this, lol
	wire writing_0 = !writer_y[4];
	wire [12:0] current_writer_address = ((((writer_y >> 5) << 4) | (writer_y & 4'b1111) ) << 7) + writer_x;

	wire [6:0] draw_x;
	wire [3:0] draw_y;
	wire [3:0] draw_bit;
	wire draw_vsync;
	
	wire [15:0] current_reader_address_0 = ((draw_y) << 7) + draw_x;
	wire [15:0] current_reader_address_1 = ((draw_y) << 7) + draw_x;

    wire [23:0] current_reader_data_a_0;
    wire [23:0] current_reader_data_a_1;
    wire [23:0] current_reader_data_b_0;
    wire [23:0] current_reader_data_b_1;
    
    // For use by blockram
    wire frame_a_0_wen = (write_frame_sel == 0) && writing_0;
    wire frame_a_1_wen = (write_frame_sel == 0) && !writing_0;
    wire frame_b_0_wen = (write_frame_sel == 1) && writing_0;
    wire frame_b_1_wen = (write_frame_sel == 1) && !writing_0;
    wire [23:0] dina = (writer_r << 16) | (writer_g << 8) | writer_b;
    wire frame_a_en = (write_frame_sel == 1);
    wire frame_b_en = (write_frame_sel == 0);
    
    wire [23:0] current_reader_data_0 = frame_a_en ? current_reader_data_a_0 : current_reader_data_b_0;
    wire [23:0] current_reader_data_1 = frame_a_en ? current_reader_data_a_1 : current_reader_data_b_1; 

    bram frame_a_0(
        .clka(core_clk),

        .addra(current_writer_address),
        .wea(frame_a_0_wen),
        .dina(dina),
        
        .addrb(current_reader_address_0),
        .enb(frame_a_en),
        .doutb(current_reader_data_a_0)
    );
    bram frame_a_1(
        .clka(core_clk),

        .addra(current_writer_address),
        .wea(frame_a_1_wen),
        .dina(dina),
        
        .addrb(current_reader_address_1),
        .enb(frame_a_en),
        .doutb(current_reader_data_a_1)
    );
    bram frame_b_0(
        .clka(core_clk),

        .addra(current_writer_address),
        .wea(frame_b_0_wen),
        .dina(dina),
        
        .addrb(current_reader_address_0),
        .enb(frame_b_en),
        .doutb(current_reader_data_b_0)
    );
    bram frame_b_1(
        .clka(core_clk),

        .addra(current_writer_address),
        .wea(frame_b_1_wen),
        .dina(dina),
        
        .addrb(current_reader_address_1),
        .enb(frame_b_en),
        .doutb(current_reader_data_b_1)
    );   
	
	reg [1:0] vsync_twostep;
    always @(posedge core_clk) begin
       vsync_twostep <= {vsync_twostep[0], draw_vsync};
    end
	
	wire core_nrst = !core_rst;
	always @(posedge core_clk or negedge core_nrst) begin
	   if (!core_nrst) begin
	       writer_pixel <= 0;
	       write_frame_sel <= 0;
	   end else begin
	       writer_pixel <= writer_pixel + 1;
	       if (vsync_twostep == 2'b10) begin
	           write_frame_sel <= write_frame_sel ^ 1;
	       end
	   end
	end
	
	wire sys_en = 1;
    blitter bt (
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
    
    wire [7:0] reader_data_r0 = current_reader_data_0[23:16];
    wire [7:0] reader_data_g0 = current_reader_data_0[15:8];
    wire [7:0] reader_data_b0 = current_reader_data_0[7:0];
    wire [7:0] reader_data_r1 = current_reader_data_1[23:16];
    wire [7:0] reader_data_g1 = current_reader_data_1[15:8];
    wire [7:0] reader_data_b1 = current_reader_data_1[7:0];
    
    wire [11:0] reader_gamma_r0;
    wire [11:0] reader_gamma_g0;
    wire [11:0] reader_gamma_b0;
    wire [11:0] reader_gamma_r1;
    wire [11:0] reader_gamma_g1;
    wire [11:0] reader_gamma_b1;
    
    gamma gr0(
        .in(reader_data_r0),
        .out(reader_gamma_r0)
    );
    gamma gg0(
        .in(reader_data_g0),
        .out(reader_gamma_g0)
    );
    gamma gb0(
        .in(reader_data_b0),
        .out(reader_gamma_b0)
    );
    gamma gr1(
        .in(reader_data_r1),
        .out(reader_gamma_r1)
    );
    gamma gg1(
        .in(reader_data_g1),
        .out(reader_gamma_g1)
    );
    gamma gb1(
        .in(reader_data_b1),
        .out(reader_gamma_b1)
    );
    
    assign LED_R0 = reader_gamma_r0 >> draw_bit;
    assign LED_G0 = reader_gamma_g0 >> draw_bit;
    assign LED_B0 = reader_gamma_b0 >> draw_bit;
    assign LED_R1 = reader_gamma_r1 >> draw_bit;
    assign LED_G1 = reader_gamma_g1 >> draw_bit;
    assign LED_B1 = reader_gamma_b1 >> draw_bit;

//    assign LED_R0 = (draw_x == 0) ? 255 : 0;
//    assign LED_G0 = (draw_x == 127) ? 255 :0;
//    assign LED_B0 = (draw_y == 0) ? 255:0;
//    assign LED_R1 = (draw_x == 127) ? 255 : 0;
//    assign LED_G1 = (draw_x == 0) ? 255 : 0;
//    assign LED_B1 = (draw_y == 15) ? 255 : 0;

	// User logic ends

	endmodule
