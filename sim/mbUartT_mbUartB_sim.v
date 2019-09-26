`timescale 10ns/10ns

module mbUartT_mbUartB_sim();

reg 		w_clk;
reg 		w_rst_n;                   
wire		w_bps_flag;
wire  		w_bps_start;
reg			w_data_f;
reg	 [7:0]	w_data;
wire 		w_send_finish;

wire 		w_uart_done;
wire [7:0] 	w_uart_data;

wire 		w_tx_rx;

mbUartT t(
	.clk			(w_clk),
	.rst_n			(w_rst_n),
	.bps_start		(w_bps_start), 
	.bps_flag		(w_bps_flag), 
	.data			(w_data), 
	.data_f 		(w_data_f), 
	.send_finish 	(w_send_finish),
	.uart_tx		(w_tx_rx)
);

mbUartB b(
	.clk 			(w_clk),
	.rst_n 			(w_rst_n),
	.bps_start 		(w_bps_start),
	.bps_flag 		(w_bps_flag)
);

mbUartR r(
	.clk 			(w_clk),
	.rst_n 			(w_rst_n),
	.uart_rxd 		(w_tx_rx),
	.uart_done 		(w_uart_done),
	.uart_data 		(w_uart_data)
);

initial                                                
begin         

	w_clk = 1'b1;
	w_rst_n = 1'b1;

	w_data = 8'h00;
	w_data_f = 1'b0;

	// start
	#1 w_rst_n = 1'b0;
	#1 w_rst_n = 1'b1;

	#10

	w_data = 8'h84;
	w_data_f = 1'b1;

	#2
	w_data = 8'h00;
	w_data_f = 1'b0;

	
	#10000000 $stop;
end                                                    
always                                                                  
begin                                                  
	#1 w_clk = ~w_clk;
end                                                    
endmodule
