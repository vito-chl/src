`timescale 10ns/10ns

module txcea_sim();

reg clk;
reg rst_n;
                                              
wire	[7:0]	w_req_cmd        ;
wire 			w_req_cmd_flag   ;
reg 			w_req_data_flag  ;
reg	    [31:0]	w_req_data       ;
wire 	[7:0]	w_bus_data       ;
wire 			w_bus_data_flag  ;
reg 			w_bus_send_finish;
reg	    [7:0]	w_cmd            ;
reg 			w_cmd_flag       ;

txcea t(
	.sys_clk(clk),
	.sys_rst(rst_n),
	.req_cmd(w_req_cmd), // 向存储模块请求数据指令
	.req_cmd_flag(w_req_cmd_flag), // 请求数据有效标志
	.req_data_flag(w_req_data_flag), // 数据返回有效标总
	.req_data(w_req_data), // 请求的数据的返回 每个传感器的数据为32位
	.bus_data(w_bus_data), // 发送到总线上的数据
	.bus_data_flag(w_bus_data_flag), // 数据有效标志	
	.bus_send_finish(w_bus_send_finish), // 数据发送完成标志
	.cmd(w_cmd), // 总线数据解析模块发送过来的命令
	.cmd_flag(w_cmd_flag) // 有效标志
);
initial                                                
begin                                                  
	clk = 1'b1;
	rst_n = 1'b0;
	w_bus_send_finish = 0;
    w_cmd             = 0;
    w_cmd_flag        = 0;
    w_req_data_flag   = 0;
    w_req_data        = 0;

	// 启动
	#10 
	rst_n = 1'b1;

//发送CMD
	#10
	w_cmd_flag = 1'b1;
	w_cmd = 8'b0000_0001;

	#2
	w_cmd_flag = 1'b0;
	w_cmd = 8'b0000_0000;

//发送REG
	#10
	w_req_data_flag = 1'b1;
	w_req_data = 32'h0000_000f; 

	#2
	w_req_data_flag = 1'b0;
	w_req_data = 32'h0000_0000; 

//id1
	#10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//id2
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//cnt1
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//cnt2
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//d1
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//d2
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//d3
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//d4
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//c1
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;
//c2
    #10 w_bus_send_finish = 1'b1;
	#2  w_bus_send_finish = 1'b0;


	#10000000 $stop;
end                                                    
always                                                                  
begin                                                  
	#1 clk = ~clk;
end                                                    
endmodule
