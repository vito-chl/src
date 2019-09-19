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
	output 	[x:0]	ret_cmd, // 返回命令
	output			ret_cmd_flg, // 返回命令有效标志
	
	// 传感器命令模块
	output	[x:0]	sen_cmd, // 发送的命令
	output	[x:0]	data	// 发送的数据
);

//*****************************  接口协议  *****************************
// * 数据<rx_data>准备好，同时给接收标志<rx_flag>一个周期的高电平
// * 命令<ret_cmd>会提前准备好，同时有效标志<ret_cmd_flg> 
//   会给一个周期的高电平
// * 数据<data>会提前准备好，同时发送一个周期命令<sen_cmd>
//**********************************************************************

//*****************************  mianStaM  *****************************
// * 
//**********************************************************************

parameter STA_WAIT 		= 13'b0000000000000; // 等待命令状态
parameter STA_HEAD_1 	= 13'b0000000000001; // 接收第一个帧头
parameter STA_HEAD_2 	= 13'b0000000000010; // 接收第二个帧头
parameter STA_CNT_1 	= 13'b0000000000100; // 接收第一个长度
parameter STA_CNT_2 	= 13'b0000000001000; // 接收第二个长度
parameter STA_DLY 		= 13'b0000000010000; // 接收到非当前ID命令，等待发送完成
parameter STA_SID 		= 13'b0000000100000; // 接收传感器ID
parameter STA_SRW 		= 13'b0000001000000; // 接收传感器读写标志
parameter STA_RCD1 		= 13'b0000010000000; // 接收数据1
parameter STA_RCD2 		= 13'b0000100000000; // 接收数据2
parameter STA_RCD3 		= 13'b0001000000000; // 接收数据3
parameter STA_RCD4 		= 13'b0010000000000; // 接收数据4
parameter STA_CRC1		= 13'b0100000000000; // CRC1
parameter STA_CRC2 		= 13'b1000000000000; // CRC2


reg []	FSM_CS; // 当前状态机状态
reg []	FSM_NS; // 状态机下一状态


endmodule