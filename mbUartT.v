// COMMIT: modbus串口服务模块
// DSC:
// 	接收数据和数据有效标志，通过串口发出，返回发送完成标志

module mbUartT(
    input clk,
    input rst_n,

    // mbUartB
    output bps_start,//控制计数开始
    input bps_flag, //数据改变点信号

    // txcea
    input [7:0] data,//数据
    input       data_f,//发送开始信号
    output      send_finish,

    // modbus
    output uart_tx
);

//*****************************  接口协议  *****************************
// * 数据<data>准备好，同时给标志<data_f>一个周期的高电平
// * 发送模块发送完成时 <send_finish>输出一个周期的高电平
//**********************************************************************

reg[7:0] tx_data;//数据寄存器
reg bps_start_r;//bps开始标志寄存
reg tx_en;//发送使能寄存器
reg[3:0] num;
reg send_finish_r;//发送完成标志

always @ (posedge clk or negedge rst_n)
	if(!rst_n) begin
		bps_start_r <= 1'bz;
		tx_en <= 1'b0;
		tx_data <= 8'b0;
		send_finish_r <= 0;
	end	
	else if(data_f) begin 
		bps_start_r <= 1'b1;
		tx_en <= 1'b1;
		tx_data <= data;
		send_finish_r <= 0;
	end
	else if(num == 4'd10) begin //数据发送完成
        // 如果接受设备是单个下降沿捕获，可以开启，如果不是，注释
		//bps_start_r <= 1'b0; 
		tx_en <= 1'b0;
		tx_data <= 8'b0;
		send_finish_r <= 1'b1;
	end
    else if(send_finish_r == 1'b1)
        send_finish_r <= 0; // 单周期信号
	else begin
		bps_start_r <= bps_start_r;
		tx_en <= tx_en;
		tx_data <= tx_data;
		send_finish_r <= 0;
	end
		 
assign bps_start = bps_start_r;
assign send_finish = send_finish_r;

reg uart_tx_r;
always @ (posedge clk or negedge rst_n)
	if(!rst_n) begin
		num <= 4'd0;
		uart_tx_r <= 1'b1;
	end
	else if(tx_en) begin
		if(bps_flag) begin
			num <= num + 1'b1;
			case (num)
				4'd0: uart_tx_r <= 1'b0; //发送起始位
				4'd1: uart_tx_r <= tx_data[0];
				4'd2: uart_tx_r <= tx_data[1];
				4'd3: uart_tx_r <= tx_data[2];
				4'd4: uart_tx_r <= tx_data[3];
				4'd5: uart_tx_r <= tx_data[4];
				4'd6: uart_tx_r <= tx_data[5];
				4'd7: uart_tx_r <= tx_data[6];
				4'd8: uart_tx_r <= tx_data[7];
				4'd9: uart_tx_r <= 1'b1; //发送停止位
				default: uart_tx_r <= 1'b1;
			endcase
		end
		else if(num == 4'd10)
			num <= 0;
	end
	
assign uart_tx = uart_tx_r;

endmodule
				
	
	
	
	
	
	
	
	
	
	
	