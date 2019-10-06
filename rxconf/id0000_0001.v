//COMMIT: 只接受一个字节的串口传感器接口

module id0000_0001(
	input			sys_clk,
	input			sys_rst,	
	
    // to reg
    output          reg_f,
    output  [39:0]  reg_d,

    // pin 
	input			rx_pin
);

wire [7:0]  data;
wire        flag;

// 例化串口接收组件
rcomp_uart r
(
    .clk(clk),
    .rst_n(sys_rst),
    .uart_rxd(rx_pin),
    .uart_done(flag),
    .uart_data(data)
);

// 传感器逻辑处理电路
assign reg_f = flag;
assign reg_d = {32'h0100_0000, data};

endmodule
