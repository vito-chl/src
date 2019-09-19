// COMMIT: 传感器接收数据寄存模块
// DSC:
// 	接收发送数据生成模块的命令，从寄存器中提出数据
// 	返回给请求模块

module reg(
	input			sys_clk,
	input			sys_rst,	
	
	input	[x:0]	store_data_f, // 数据寄存选择
	input 	[7:0]	store_data, // 数据寄存数据接口

	input	[x:0]	req_data_f, // 请求的数据选择
	input	[7:0]	req_data // 请求的数据接口
	
);



endmodule