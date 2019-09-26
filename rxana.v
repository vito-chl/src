// COMMIT: 总线数据接收解析模块
// DSC:
// 	解析来自总线的数据，进行相应处理，并发送给总线数据生成模块
//	或者发送给传感器命令模块

module rxana(
	input			sys_clk,
	input			sys_rst,
	
	// 消息接收模块接收到的消息
	input			rx_flag,// 接收数据完成的标志
	input	[7:0]	rx_data,// 接收的数据
	
	// 总线数据生成模块
	output 	[7:0]	ret_cmd, // 返回命令 
	output			ret_cmd_flg, // 返回命令有效标志
	
	// 传感器命令模块
	output	[39:0]	sen_cmd, // 前8位：传感器ID 其他：要发送给传感器的数据
	output			sen_cmd_flag	// 发送的数据 
);

//*****************************  接口协议  *****************************
// * 数据<rx_data>准备好，同时给接收标志<rx_flag>一个周期的高电平
// * 命令<ret_cmd>会提前准备好，同时有效标志<ret_cmd_flg> 
//   会给一个周期的高电平
// * 命令<sen_cmd>会提前准备好，同时有效标志<sen_cmd_flag> 
//   会给一个周期的高电平
//**********************************************************************

// 接收的数据的存储
reg [7:0] RX_DATA;
// reg [7:0] RX_DATA_R;

// always @(*) begin
// 	if(rx_flag)
// 		RX_DATA_R = rx_data;
// 	else
// 		RX_DATA_R = RX_DATA_R;
// end

// always @ (posedge sys_clk or negedge sys_rst) begin
// 	if(!sys_rst)
// 		RX_DATA <=  8'b0000_0000;
// 	else
// 		RX_DATA <=  RX_DATA_R;
// end
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst)
		RX_DATA <=  8'b0000_0000;
	else if(rx_flag)
		RX_DATA <=  rx_data;
	else;
end

//*****************************  mianStaM  *****************************
// * 
//**********************************************************************

parameter STA_WAIT 		= 12'b000000000000; // 等待命令状态
parameter STA_HEAD_1 	= 12'b000000000001; // 接收第一个ID
parameter STA_HEAD_2 	= 12'b000000000010; // 接收第二个ID
parameter STA_CNT_1 	= 12'b000000000100; // 接收第一个长度
parameter STA_CNT_2 	= 12'b000000001000; // 接收第二个长度
parameter STA_SID 		= 12'b000000010000; // 接收传感器ID
parameter STA_SRW 		= 12'b000000100000; // 接收传感器读写标志
parameter STA_RCD1 		= 12'b000001000000; // 接收数据1
parameter STA_RCD2 		= 12'b000010000000; // 接收数据2
parameter STA_RCD3 		= 12'b000100000000; // 接收数据3
parameter STA_RCD4 		= 12'b001000000000; // 接收数据4
parameter STA_CRC1		= 12'b010000000000; // CRC1
parameter STA_CRC2 		= 12'b100000000000; // CRC2
parameter STA_DLY		= 12'b111111111111; // 等待
parameter STA_SENDCMD	= 12'b110000000000; // 发送命令

reg [11:0]	FSM_CS; // 当前状态机状态
reg [11:0]	FSM_NS; // 状态机下一状态

reg [15:0]	REC_ID; // ID缓存
reg [15:0]	REC_ID_R; // 寄存

reg [15:0]	REC_CNT; // 接收计数
reg [15:0]	REC_CNT_R; // 寄存

reg [15:0]	SENSOR; // 传感器相关 高8位ID,低8位RW
reg [15:0]	SENSOR_R;

reg [31:0]	DATA; // 接收的数据
reg [31:0]	DATA_R;

reg [7:0]	RET_CMD; // 返回的数据 要读取的传感器id
reg [7:0]	RET_CMD_R;

reg RET_CMD_FLAG; // 命令返回标志
reg RET_CMD_FLAG_R; 

reg [39:0]	SEND_CMD; // 返回的数据 要读取的传感器id
reg [39:0]	SEND_CMD_R;

reg SEND_CMD_FLAG; // 命令返回标志
reg SEND_CMD_FLAG_R; 

wire ID_RIGHT =  (REC_ID == 16'b0000_0000_0000_0001); // 判读ID是否正确 
wire CNT_END = (REC_CNT == 16'b0000_0000_0000_0000); // 判断是否计数结束 
wire SEN_R = (SENSOR[1:0] == 2'b11); // 02为读标志
wire SEN_W = ~SEN_R;

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
		STA_WAIT: begin // 等待过程，接到数据变成 HEAD1 否则保持等待
			if(rx_flag)
				FSM_NS = STA_HEAD_1;
			else
				FSM_NS = STA_WAIT;
		end
		STA_HEAD_1: begin // 接收头1
			if(rx_flag)
				FSM_NS = STA_HEAD_2;
			else
				FSM_NS = STA_HEAD_1;
		end
		STA_HEAD_2: begin // 接收头2
			if(rx_flag)
				FSM_NS = STA_CNT_1;
			else
				FSM_NS = STA_HEAD_2;
		end
		STA_CNT_1: begin // 接收字节数1
			if(rx_flag)
				FSM_NS = STA_CNT_2;
			else
				FSM_NS = STA_CNT_1;
		end
		STA_CNT_2: begin // 接收字节数2
			if(rx_flag)
				if(ID_RIGHT) // ID正确，进入下一个阶段
					FSM_NS = STA_SID;
				else // 不正确，进入计数等待
					FSM_NS = STA_DLY;
			else
				FSM_NS = STA_CNT_2;
		end
		STA_SID: begin // 接收传感器ID
			if(rx_flag)
				FSM_NS = STA_SRW;
			else
				FSM_NS = STA_SID;
		end
		STA_SRW: begin // 接收读写标志位
			if(rx_flag) begin
				if(SEN_W)
					FSM_NS = STA_RCD1;
				else
					FSM_NS = STA_CRC1;
			end
			else
				FSM_NS = STA_SRW;
		end
		STA_RCD1: begin // 接收第一个数据
			if(rx_flag)
				FSM_NS = STA_RCD2;
			else
				FSM_NS = STA_RCD1;
		end
		STA_RCD2: begin // 接收第二个数据
			if(rx_flag)
				FSM_NS = STA_RCD3;
			else
				FSM_NS = STA_RCD2;
		end
		STA_RCD3: begin // 接收第三个数据
			if(rx_flag)
				FSM_NS = STA_RCD4;
			else
				FSM_NS = STA_RCD3;
		end
		STA_RCD4: begin // 接收第四个数据
			if(rx_flag)
				FSM_NS = STA_CRC1;
			else
				FSM_NS = STA_RCD4;
		end
		STA_CRC1: begin // 接收CRC1
			if(rx_flag)
				FSM_NS = STA_CRC2;
			else
				FSM_NS = STA_CRC1;
		end
		STA_CRC2: begin // 接收CRC2
			//if(rx_flag)
				FSM_NS = STA_SENDCMD;
			//else
			//	FSM_NS = STA_CRC2;
		end
		STA_SENDCMD: begin // 一个周期完成指令发送
			FSM_NS = STA_WAIT;
		end
		STA_DLY: begin // ID不正确，接收等待
			if(rx_flag)
				if(CNT_END)//计数结束
					FSM_NS = STA_WAIT;
				else
					FSM_NS = STA_DLY;
			else
				FSM_NS = STA_DLY;
		end
		default;
	endcase
end

// 输出选择器
always @(*) begin
	case(FSM_CS)
		STA_WAIT: begin // 等待过程，接到数据变成 HEAD1 否则保持等待
			RET_CMD_FLAG_R = 1'b0; // 清除发送标志
			REC_ID_R = 16'b0000_0000_0000_0000;
			RET_CMD_R = 8'b0000_0000;
			SEND_CMD_R = 40'h0000_0000_00;
			SEND_CMD_FLAG_R = 1'b0;
			REC_CNT_R = 16'h0000;
		end
		STA_HEAD_1: begin // 接收头1
			REC_ID_R = {RX_DATA, 8'b0000_0000};
		end
		STA_HEAD_2: begin // 接收头2
			REC_ID_R[7:0] = RX_DATA;
		end
		STA_CNT_1: begin // 接收字节数1
			if(!ID_RIGHT)
				REC_CNT_R[15:8] = RX_DATA;
			else
				REC_CNT_R[15:8] = 8'b0000_0000;
		end
		STA_CNT_2: begin // 接收字节数2
			if(!ID_RIGHT) begin
				REC_CNT_R[7:0] = RX_DATA;
				//REC_CNT_R = REC_CNT_R + 16'b0000_0000_0000_0001;
			end
			else
				REC_CNT_R[7:0] = 8'b0000_0000;
		end
		STA_SID: begin // 接收传感器ID
			SENSOR_R[15:8] = RX_DATA;
		end
		STA_SRW: begin // 接收读写标志位
			SENSOR_R[7:0] = RX_DATA;
		end
		STA_RCD1: begin // 接收第一个数据
			DATA_R[7:0] = RX_DATA;
		end
		STA_RCD2: begin // 接收第二个数据
			DATA_R[15:8] = RX_DATA;
		end
		STA_RCD3: begin // 接收第三个数据
			DATA_R[23:16] = RX_DATA;
		end
		STA_RCD4: begin // 接收第四个数据
			DATA_R[31:24] = RX_DATA;
		end
		STA_CRC1: begin // 接收CRC1
			
		end
		STA_CRC2: begin // 接收CRC2
			
		end
		STA_SENDCMD: begin
			if(SEN_R) begin// 发送读取命令
				RET_CMD_R = SENSOR[15:8];
				RET_CMD_FLAG_R = 1'b1;
			end
			else if(SEN_W) begin
				SEND_CMD_R = {SENSOR[15:8], DATA};
				SEND_CMD_FLAG_R = 1'b1;
			end
			else;
		end
		STA_DLY: begin // ID不正确，接收等待，每接收一个数据减1
			if(rx_flag)
				REC_CNT_R = REC_CNT_R - 16'b0000_0000_0000_0001; // 计数器减1
			else
				REC_CNT_R = REC_CNT_R;
		end
		default;
	endcase
end

//输出更新器
always @(posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		REC_ID <= 16'b0000_0000_0000_0000;
		REC_CNT <= 16'b0000_0000_0000_0000;
		SENSOR <= 16'b0000_0000_0000_0000;
		DATA <= 32'h0000_0000;
		RET_CMD <= 8'b0000_0000;
		RET_CMD_FLAG <= 1'b0;
		SEND_CMD <= 40'h0000_0000_00;
		SEND_CMD_FLAG <= 1'b0;
	end
	else begin
		REC_ID <= REC_ID_R;
		REC_CNT <= REC_CNT_R;
		SENSOR <= SENSOR_R;
		DATA <= DATA_R;
		RET_CMD <= RET_CMD_R;
		RET_CMD_FLAG <= RET_CMD_FLAG_R;
		SEND_CMD <= SEND_CMD_R;
		SEND_CMD_FLAG <= SEND_CMD_FLAG_R;
	end
end

// 总线数据生成模块
assign	ret_cmd = RET_CMD; // 返回命令 
assign	ret_cmd_flg = RET_CMD_FLAG; // 返回命令有效标志

// 传感器命令模块
assign	sen_cmd = SEND_CMD; // 前8位：传感器ID 其他：要发送给传感器的数据
assign	sen_cmd_flag = SEND_CMD_FLAG;	// 发送的数据 


endmodule
