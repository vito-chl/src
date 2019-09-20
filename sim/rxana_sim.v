`timescale 10ns/10ns

module rxana_sim();

reg clk;
reg rst_n;
                                              
reg w_rx_flag;
reg [7:0] w_rx_data;

wire [7:0] w_ret_cmd;
wire w_ret_cmd_flg;

wire [39:0] w_sen_cmd;
wire w_sen_cmd_flg;

rxana r1(
	.sys_clk(clk),
	.sys_rst(rst_n),
	
	// 消息接收模块接收到的消息
	.rx_flag(w_rx_flag),// 接收数据完成的标志
	.rx_data(w_rx_data),// 接收的数据
	
	// 总线数据生成模块
	.ret_cmd(w_ret_cmd), // 返回命令 
	.ret_cmd_flg(w_ret_cmd_flg), // 返回命令有效标志
	
	// 传感器命令模块
	.sen_cmd(w_sen_cmd), // 前8位：传感器ID 其他：要发送给传感器的数据
	.sen_cmd_flag(w_sen_cmd_flg)	// 发送的数据 
);

initial                                                
begin                                                  
	clk = 1'b1;
	rst_n = 1'b0;
	w_rx_flag = 1'b0;
	w_rx_data = 8'b0000_0000;
	
	// 启动
	#10 
	rst_n = 1'b1;

//发送第一个ID
	#10
	w_rx_flag = 1'b1;
	w_rx_data = 8'b0000_0000;

	#2
	w_rx_flag = 1'b0;
	w_rx_data = 8'b0000_0000;

//发送第二个ID
	#10
	w_rx_flag = 1'b1;
	w_rx_data = 8'b0000_0001; // 发送正确的ID
	//w_rx_data = 8'b0000_0000; // 发送不正确的ID

	#2
	w_rx_flag = 1'b0;
	w_rx_data = 8'b0000_0000;

//发送第一个长度
	#10
	w_rx_flag = 1'b1;
	w_rx_data = 8'b0000_0000;

	#2
	w_rx_flag = 1'b0;
	w_rx_data = 8'b0000_0000;

//发送第二个长度
	#10
	w_rx_flag = 1'b1;
	w_rx_data = 8'b0000_0010;

	#2
	w_rx_flag = 1'b0;
	w_rx_data = 8'b0000_0000;

//发送传感器ID
	#10
	w_rx_flag = 1'b1;
	w_rx_data = 8'b0000_0001;

	#2
	w_rx_flag = 1'b0;
	w_rx_data = 8'b0000_0000;

//发送读写控制位
	#10
	w_rx_flag = 1'b1;
	w_rx_data = 8'b0000_0011; // 读标志

	#2
	w_rx_flag = 1'b0;
	w_rx_data = 8'bxxxx_xxxx;

//发送第一个CRC
	#10
	w_rx_flag = 1'b1;
	w_rx_data = 8'b0000_0001;

	#2
	w_rx_flag = 1'b0;
	w_rx_data = 8'bxxxx_xxxx;

//发送第二CRC
	#10
	w_rx_flag = 1'b1;
	w_rx_data = 8'b0000_0010;

	#2
	w_rx_flag = 1'b0;
	w_rx_data = 8'bxxxx_xxxx;

	#10000000 $stop;
end                                                    
always                                                                  
begin                                                  
	#1 clk = ~clk;
end                                                    
endmodule
