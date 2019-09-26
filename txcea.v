// COMMIT: 发送数据生成模块
// DSC:
// 	接收数据解析模块的命令，从传感器接收数据缓存模块提出数据
// 	生成发送的数据，通过串口发送模块发送出去

module txcea(
	input			sys_clk,
	input			sys_rst,
	
	// 数据寄存模块接口
	output	[7:0]	req_cmd, // 向存储模块请求数据指令
	output 			req_cmd_flag, // 请求数据有效标志
	input 			req_data_flag, // 数据返回有效标总
	input	[31:0]	req_data, // 请求的数据的返回 每个传感器的数据为32位
	
	// 总线发送接口
	output 	[7:0]	bus_data, // 发送到总线上的数据
	output 			bus_data_flag, // 数据有效标志	
	input 			bus_send_finish, // 数据发送完成标志

	// 总线数据解析接口
	input	[7:0]	cmd, // 总线数据解析模块发送过来的命令
	input 			cmd_flag // 有效标志
);

//*****************************  接口协议  *****************************
// * 数据<req_cmd>准备好，同时给接收标志<req_cmd_flag>一个周期的高电平
// * 要求<req_data>准备好，同时将<req_data_flag>置高一个周期即完成接收
// * 数据<bus_data>准备好，同时给标志<bus_data_flag>一个周期的高电平，
//   当数据发送完成时发送给<bus_send_finish>一个周期高电平
// * 要求<cmd>准备好，同时将<cmd_flag>置高一个周期
//**********************************************************************

//*****************************  输入锁存  ******************************
// * 
//**********************************************************************

// 命令的存储
reg [7:0] rx_cmd;
// reg [7:0] rx_cmd_r;

// always @(*) begin
// 	if(cmd_flag)
// 		rx_cmd_r = cmd;
// 	else
// 		rx_cmd_r = rx_cmd_r;
// end

// always @ (posedge sys_clk or sys_rst) begin
// 	if(!sys_rst)
// 		rx_cmd <=  8'b0000_0000;
// 	else
// 		rx_cmd <=  rx_cmd_r;
// end
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst)
		rx_cmd <=  8'b0000_0000;
	else if(rx_flag)
		rx_cmd <=  cmd;
	else
		rx_cmd <=  rx_cmd;
end

// 请求返回的数据的存储
reg [31:0] rx_req_data;
reg [31:0] rx_req_data_r;

always @(*) begin
	if(req_data_flag)
		rx_req_data_r = req_data;
	else
		rx_req_data_r = rx_req_data_r;
end

always @ (posedge sys_clk or sys_rst) begin
	if(!sys_rst)
		rx_req_data <=  32'h0000_0000;
	else
		rx_req_data <=  rx_req_data_r;
end

//*****************************  mianStaM  *****************************
// * 
//**********************************************************************

parameter STA_WAIT 		= 12'b000000000000; // 等待命令状态
parameter STA_REQ_REG 	= 12'b000000000001; // 请求数据状态
parameter STA_REC_REG	= 12'b000000000010;
parameter STA_ID_1 		= 12'b000000000100; // 发送第一个ID
parameter STA_ID_2 		= 12'b000000001000; // 发送第二个ID
parameter STA_CNT_1 	= 12'b000000010000; // 发送第一个字节数
parameter STA_CNT_2		= 12'b000000100000; // 发送第二个字节数
parameter STA_DATA_1	= 12'b000001000000; // 发送第一个数据
parameter STA_DATA_2 	= 12'b000010000000; // 发送第二个数据
parameter STA_DATA_3 	= 12'b000100000000; // 发送第三个数据
parameter STA_DATA_4 	= 12'b001000000000; // 发送第四个数据
parameter STA_CRC1 		= 12'b010000000000; // 发送CRC1
parameter STA_CRC2		= 12'b100000000000; // 发送CRC2

reg [11:0]	FSM_CS; // 当前状态机状态
reg [11:0]	FSM_NS; // 状态机下一状态

// 状态更新器
always @(posedge sys_clk or posedge sys_rst) begin
	if(!sys_rst) begin
		FSM_CS <= STA_WAIT;
	end
	else begin
		FSM_CS <= FSM_NS;
	end
end

// 状态选择器
always @(*) begin
	case(FSM_CS)
		STA_WAIT: begin // 等待过程，接到数据变成进入请求状态 否则保持等待
			if(cmd_flag)
				FSM_NS = STA_REQ_REG;
			else
				FSM_NS = STA_WAIT;
		end
		STA_REQ_REG: begin // 请求数据
			FSM_NS = STA_REC_REG;
		end
		STA_REC_REG: begin // 等待接收到请求返回的数据
			if(req_data_flag)
				FSM_NS = STA_ID_1;
			else
				FSM_NS = STA_REC_REG;
		end
		STA_ID_1: begin // 发送ID1
			if(bus_send_finish)
				FSM_NS = STA_ID_2;
			else
				FSM_NS = STA_ID_1;
		end
		STA_ID_2: begin // 发送 ID2
			if(bus_send_finish)
				FSM_NS = STA_CNT_1;
			else
				FSM_NS = STA_ID_2;
		end
		STA_CNT_1: begin // 发送字节数1
			if(bus_send_finish)
				FSM_NS = STA_CNT_2;
			else
				FSM_NS = STA_CNT_1;
		end
		STA_CNT_2: begin //发送字节数2
			if(bus_send_finish)
				FSM_NS = STA_DATA_1;
			else
				FSM_NS = STA_CNT_2;
		end
		STA_DATA_1: begin //发送第一个数据
			if(bus_send_finish)
				FSM_NS = STA_DATA_2;
			else
				FSM_NS = STA_DATA_1;
		end
		STA_DATA_2: begin // 发送第二个数据
			if(bus_send_finish)
				FSM_NS = STA_DATA_3;
			else
				FSM_NS = STA_DATA_2;
		end
		STA_DATA_3: begin // 发送第三个数据
			if(bus_send_finish)
				FSM_NS = STA_DATA_4;
			else
				FSM_NS = STA_DATA_3;
		end
		STA_DATA_4: begin // 发送第四个数据
			if(bus_send_finish)
				FSM_NS = STA_CRC1;
			else
				FSM_NS = STA_DATA_4;
		end
		STA_CRC1: begin // 发送CRC1
			if(bus_send_finish)
				FSM_NS = STA_CRC2;
			else
				FSM_NS = STA_CRC1;
		end
		STA_CRC2: begin // 发送CRC2
			if(bus_send_finish)
				FSM_NS = STA_WAIT;
			else
				FSM_NS = STA_CRC2;
		end
		default;
	endcase
end

// 输出寄存
reg [7:0] out_req_cmd_r;
reg 	  out_req_cmd_flag_r;

reg [7:0] out_bus_data_r;
reg 	  out_bus_data_flag_r;

// 单周期计数变量
reg id_1_send;
reg id_2_send;
reg cnt_1_send;
reg cnt_2_send;
reg data_1_send;
reg data_2_send;
reg data_3_send;
reg data_4_send;
reg crc_1_send;
reg crc_2_send;

// 输出选择器
always @(*) begin
	case(FSM_CS)
		STA_WAIT: begin // 进行一些清除操作
			out_req_cmd_r = 8'h00;
			out_req_cmd_flag_r = 1'b0;
			out_bus_data_r = 8'h00;
			out_bus_data_flag_r = 1'b0;
		end
		STA_REQ_REG: begin
			out_req_cmd_r = rx_cmd_r;
			out_req_cmd_flag_r = 1'b1;
		end
		STA_REC_REG: begin 
			out_req_cmd_r = 8'h00;
			out_req_cmd_flag_r = 1'b0;
		end
		STA_ID_1: begin // 发送ID1
			if(id_1_send) begin // 实现单周期发送
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_ID_2: begin // 发送 ID2
			if(id_2_send) begin // 实现单周期发送
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_CNT_1: begin // 发送字节数1
			if(cnt_1_send) begin // 实现单周期发送
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_CNT_2: begin // 接收字节数2
			if(cnt_2_send) begin // 实现单周期发送
				out_bus_data_r = 8'h04;
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_DATA_1: begin //发送第一个数据
			if(data_1_send) begin // 实现单周期发送
				out_bus_data_r = rx_req_data[31:24];
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_DATA_2: begin // 发送第二个数据
			if(data_2_send) begin // 实现单周期发送
				out_bus_data_r = rx_req_data[23:16];
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_DATA_3: begin // 发送第三个数据
			if(data_3_send) begin // 实现单周期发送
				out_bus_data_r = rx_req_data[15:8];
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_DATA_4: begin // 发送第四个数据
			if(data_4_send) begin // 实现单周期发送
				out_bus_data_r = rx_req_data[7:0];
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_CRC1: begin // 发送CRC1
			if(crc_1_send) begin // 实现单周期发送
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		STA_CRC2: begin // 发送CRC2
			if(crc_2_send) begin // 实现单周期发送
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b1;
			end
			else begin		
				out_bus_data_r = 8'h00;
				out_bus_data_flag_r = 1'b0;
			end
		end
		default;
	endcase
end

// 单周期计数器
always @(posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		id_1_send 	<= 1'b1;
		id_2_send 	<= 1'b1;
		cnt_1_send 	<= 1'b1;
		cnt_2_send 	<= 1'b1;
		data_1_send <= 1'b1;
		data_2_send <= 1'b1;
		data_3_send <= 1'b1;
		data_4_send <= 1'b1;
		crc_1_send 	<= 1'b1;
		crc_2_send 	<= 1'b1;
	end
	case(FSM_CS) 
		STA_WAIT: begin // 进行一些清除操作
			id_1_send 	<= 1'b1;
			id_2_send 	<= 1'b1;
			cnt_1_send 	<= 1'b1;
			cnt_2_send 	<= 1'b1;
			data_1_send <= 1'b1;
			data_2_send <= 1'b1;
			data_3_send <= 1'b1;
			data_4_send <= 1'b1;
			crc_1_send 	<= 1'b1;
			crc_2_send 	<= 1'b1;
		end
		STA_ID_1: id_1_send 	<= 1'b0;
		STA_ID_2: id_2_send 	<= 1'b0;  
		STA_CNT_1: cnt_1_send 	<= 1'b0;
		STA_CNT_2: cnt_2_send 	<= 1'b0;
		STA_DATA_1: data_1_send <= 1'b0;
		STA_DATA_2: data_2_send <= 1'b0;
		STA_DATA_3: data_3_send <= 1'b0;
		STA_DATA_4: data_4_send <= 1'b0;
		STA_CRC1: crc_1_send 	<= 1'b0;
		STA_CRC2: crc_2_send 	<= 1'b0;
		default;
	endcase
end

// 输出更新器
reg [7:0] out_req_cmd;
reg 	  out_req_cmd_flag;

reg [7:0] out_bus_data;
reg 	  out_bus_data_flag;

always @(posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		out_req_cmd <= 8'h00;
		out_bus_data <= 8'h00;
		out_req_cmd_flag <= 1'b0;
		out_bus_data_flag <= 1'b0;
	end
	else begin
		out_req_cmd <= out_req_cmd_r;
		out_bus_data <= out_bus_data_r;
		out_req_cmd_flag <= out_req_cmd_flag_r;
		out_bus_data_flag <= out_bus_data_flag_r;
	end
end

assign req_cmd = out_req_cmd; // 向存储模块请求数据指令
assign req_cmd_flag = out_req_cmd_flag; // 请求数据有效标志

assign bus_data = out_bus_data; // 发送到总线上的数据
assign bus_data_flag = out_bus_data_flag; // 数据有效标志	

endmodule