`timescale 10ns/10ns

module reg_sim();

reg 		w_clk;
reg 		w_rst_n;                   
reg			w_store_data_f;
reg  [39:0]	w_store_data;
reg			w_req_id_f;
reg	 [7:0]	w_req_id;
wire [31:0]	w_req_data;
wire  		w_req_data_f;


regm t(
	.sys_clk		(w_clk),
	.sys_rst		(w_rst_n),
	.store_data_f	(w_store_data_f), 
	.store_data		(w_store_data), 
	.req_id_f		(w_req_id_f), 
	.req_id 		(w_req_id), 
	.req_data 		(w_req_data), 
	.req_data_f 	(w_req_data_f)
);

initial                                                
begin         

	w_clk = 1'b1;
	w_rst_n = 1'b1;

	w_store_data_f = 0;
	w_store_data = 0;
	w_req_id_f = 0;
	w_req_id = 0;

	// start
	#1 w_rst_n = 1'b0;
	#1 w_rst_n = 1'b1;

	#10

	w_store_data_f <= 1'b1;
	w_store_data <= 40'h01_ffff_1111;

	#2

	w_store_data_f <= 1'b0;
	w_store_data <= 40'h00_0000_0000;

	#10
	w_req_id <= 8'h01;
	w_req_id_f <= 1'b1;

	#2

	w_req_id <= 8'h00;
	w_req_id_f <= 1'b0;
	
	#10000000 $stop;
end                                                    
always                                                                  
begin                                                  
	#1 w_clk = ~w_clk;
end                                                    
endmodule
