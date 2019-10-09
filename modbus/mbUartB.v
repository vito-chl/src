// COMMIT: modbus串口服务模块
// DSC:
// 	波特率产生器

module mbUartB(
	//输入
	input clk,
	input rst_n,
	input bps_start,
	output bps_flag
);

parameter CLK_FRQ =	50_000_000;		//主时钟周期 ns
parameter BPS_SET = 115200;	//串口波特率

parameter BPS_PARA = (CLK_FRQ / BPS_SET);	//计数值
parameter BPS_PARA_2 = (BPS_PARA / 2);		//二分频计数值

reg[12:0] bps_cnt;//计数器

reg bps_flag_r;//采样点输出寄存器

//start后开始从 0~BPS_PARA 计数
always @ (posedge clk or negedge rst_n)
	if(!rst_n) 
		bps_cnt <= 13'b0;
	else if((bps_cnt == BPS_PARA) || !bps_start)
		bps_cnt <= 13'b0;
	else
		bps_cnt <= bps_cnt + 1'b1;
		
//在 bps_cnt == 'BPS_PARA_2 时设置采样标志
always @ (posedge clk or negedge rst_n)
	if(!rst_n) 
		bps_flag_r <= 1'b0;
	else if(bps_cnt == BPS_PARA_2)
		bps_flag_r <= 1'b1;
	else
		bps_flag_r <= 1'b0;
		
//输出
assign bps_flag = bps_flag_r;

endmodule
