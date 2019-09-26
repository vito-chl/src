// COMMIT: 传感器接收数据寄存模块
// DSC:
// 	接收发送数据生成模块的命令，从寄存器中提出数据
// 	返回给请求模块

module regm(
	input			sys_clk,
	input			sys_rst,	
	
	// rxcomb接口
	input			store_data_f, // 数据寄存选择
	input 	[39:0]	store_data, // 数据寄存数据接口 前8位表示id后面的为数据

	// txcea接口
	input			req_id_f, // 请求的数据选择
	input	[7:0]	req_id, // 请求的数据接口
	output  [31:0]	req_data, 
	output  		req_data_f
);

//*****************************  输入锁存  ******************************
// * 
//**********************************************************************
// txcea接口的缓存
reg [7:0] in_req_id;
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst)
		in_req_id <=  8'b0000_0000;
	else if(req_id_f)
		in_req_id <=  req_id;
	else
		in_req_id <=  in_req_id;
end

reg [1:0] dly_cnt;
wire dly_end = (dly_cnt == 2'b10);

// 延迟使能信号
reg dly_cnt_f;
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		dly_cnt_f <= 1'b0;
	end
	else if(req_id_f) begin
		dly_cnt_f <= 1'b1;
	end
	else if(dly_end)
		dly_cnt_f <= 1'b0;
	else;
end

// 延迟
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		dly_cnt <= 1'b0;
	end
	else begin
		if (req_id_f)
			dly_cnt <= 2'b00;
		else begin
			if(dly_cnt_f)
				dly_cnt <= dly_cnt + 2'b1;
			else
				dly_cnt <= 2'b00;
		end
	end
end

// 寄存器表
reg [31:0] reg_data_00;
reg [31:0] reg_data_01;
reg [31:0] reg_data_02;
reg [31:0] reg_data_03;
reg [31:0] reg_data_04;
reg [31:0] reg_data_05;
reg [31:0] reg_data_06;
reg [31:0] reg_data_07;

//  输入控制
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		reg_data_00 <= 32'h0000_0000;
		reg_data_01 <= 32'h0000_0000;
		reg_data_02 <= 32'h0000_0000;
		reg_data_03 <= 32'h0000_0000;
		reg_data_04 <= 32'h0000_0000;
		reg_data_05 <= 32'h0000_0000;
		reg_data_06 <= 32'h0000_0000;
		reg_data_07 <= 32'h0000_0000;
	end
	else if(store_data_f) begin
		case (store_data[39:32])
			8'h00: reg_data_00 <= store_data[31:0];
			8'h01: reg_data_01 <= store_data[31:0];
			8'h02: reg_data_02 <= store_data[31:0];
			8'h03: reg_data_03 <= store_data[31:0];
			8'h04: reg_data_04 <= store_data[31:0];
			8'h05: reg_data_05 <= store_data[31:0];
			8'h06: reg_data_06 <= store_data[31:0];
			8'h07: reg_data_07 <= store_data[31:0];
			default:;
		endcase	
	end
end

// 输出控制
reg [31:0]  inner_req_data;
reg 		inner_req_data_f;
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		inner_req_data 		<= 32'h0000_0000;
		inner_req_data_f 	<= 1'b0;
	end
	else begin
		if (dly_end) begin
			inner_req_data_f <= 1'b1;
			case (in_req_id)
				8'h00: inner_req_data <= reg_data_00;
				8'h01: inner_req_data <= reg_data_01;
				8'h02: inner_req_data <= reg_data_02;
				8'h03: inner_req_data <= reg_data_03;
				8'h04: inner_req_data <= reg_data_04;
				8'h05: inner_req_data <= reg_data_05;
				8'h06: inner_req_data <= reg_data_06;
				8'h07: inner_req_data <= reg_data_07;
				default: inner_req_data <= 32'h0000_0000;
			endcase
		end
		else begin
			inner_req_data_f <= 1'b0;
		end
	end
end

assign  req_data = inner_req_data;
assign 	req_data_f = inner_req_data_f;

endmodule