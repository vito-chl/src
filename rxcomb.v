// COMMIT: 传感器接收数据汇总模块
// DSC:
// 	接收来自各个串口接收模块的消息
// 	发送给数据缓存模块

module rxcomb(
	input			sys_clk,
	input			sys_rst,	
	
	// sensor
	input [39:0]	id01_d,
	input 			id01_f,
	
	input [39:0]	id02_d,
	input [39:0]    id02_f,

	// reg
	output 			reg_f,
	output [39:0]   reg_d
);

//******************************** ID 01 接收的数据的存储 **************
reg [39:0] ID01_DATA;
reg 	   ID01_REQ;
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		ID01_DATA <=  40'h0000_0000_00;
		ID01_REQ  <=  1'b0;
	end
	else if(id01_f) begin
		ID01_REQ  <= 1'b1;
		ID01_DATA <=  id01_d;
	end
	else begin
		if(ID01_ASW == 1'b1) begin
			ID01_REQ  <= 1'b0;
			ID01_DATA <= ID01_DATA;
		end
		else begin
			ID01_REQ  <= ID01_REQ;
			ID01_DATA <= ID01_DATA;
		end
	end
end

//******************************** ID 02 接收的数据的存储 **************
reg [39:0] ID02_DATA;
reg 	   ID02_REQ;
always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		ID02_DATA <=  40'h0000_0000_00;
		ID02_REQ  <=  1'b0;
	end
	else if(id02_f) begin
		ID02_REQ  <= 1'b1;
		ID02_DATA <= id02_d;
	end
	else begin
		if(ID02_ASW == 1'b1) begin
			ID02_REQ  <= 1'b0;
			ID02_DATA <= ID02_DATA;
		end
		else begin
			ID02_REQ  <= ID02_REQ;
			ID02_DATA <= ID02_DATA;
		end
	end
end


//******************************** 数据的仲裁与发送（有优先级）**************
reg        regflag;
reg [39:0] regdata;

reg        ID01_ASW;
reg        ID02_ASW;

always @ (posedge sys_clk or negedge sys_rst) begin
	if(!sys_rst) begin
		ID01_ASW  <=  1'b0;
		ID02_ASW  <=  1'b0;
		regflag   <=  1'b0;
		regdata   <=  39'h0000_0000_00;
	end
	else begin
		if(regflag == 1'b1) begin // 发送信号给寄存模块
			regflag == 1'b0;
			ID01_ASW <= 1'b0;
			ID02_ASW <= 1'b0;
		end
		else begin
			if(ID01_REQ == 1'b1) begin
				regflag <= 1'b1;
				regdata <= ID01_DATA;
				ID01_ASW <= 1'b1;
			end
			// 添加其他的消息
			if(ID02_REQ == 1'b1) begin
				regflag <= 1'b1;
				regdata <= ID01_DATA;
				ID02_ASW <= 1'b1;
			end
			else begin
				regflag <= 1'b0;
				regdata <= regdata;
			end
		end
	end
end


assign reg_d = regdata;
assign reg_f = regflag;

endmodule