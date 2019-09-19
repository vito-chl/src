// COMMIT: 发送数据生成模块
// DSC:
// 	接收数据解析模块的命令，从传感器接收数据缓存模块提出数据
// 	生成发送的数据，通过串口发送模块发送出去

module txcea(
	input			sys_clk,
	input			sys_rst,
	
	output	[x:0]	req_cmd, // 请求数据标志
	input	[7:0]	ret_data, // 请求的数据的返回
	
	input	[x:0]	cmd // 总线数据解析模块发送过来的命令
);



endmodule