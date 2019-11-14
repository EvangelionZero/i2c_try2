module i2c_try2(clk,rst,en,button,scl,led,sda);
	input clk,rst,button,en;
	output scl,led;
	inout sda;
	reg [9:0]button_cnt;
	reg [8:0]en_wr_cnt;
	reg scl,led;
	reg en_wr;
	reg sda_buf;
	reg link;
	reg over_flag;
	reg [1:0]seq_cnt;
	reg [4:0]i2c_substate;
	reg machine_state;
	reg [1:0]i2c_state;
	reg [7:0]cmd=8'd1;
	reg [7:0]data;
	reg [1:0]bit_cycle_cnt;
	reg [7:1]cat_addr=7'b0100000;
	reg rw_cmd=1'b0;//0 for write,1 for read
	parameter
		button_max=10'd1023,
		en_wr_cnt_max=10'd511;
	parameter //camera poweron sequence (data) parameter
		poweron_seq1=8'b00000001,
		poweron_seq2=8'b00000011,
		poweron_seq3=8'b00000111;
	parameter //machine state parameter
		machine_ini=1'b0,
		machine_w=1'b1;
	parameter //i2c state parameter
		t_slave_addr=2'b00,
		command=2'b01,
		data_to_port=2'b10;
	parameter //i2c substate parameter
		start=5'b00000, 
		first=5'b00001,
		second=5'b00010,
		third=5'b00011, 
		fourth=5'b00100,
		fifth=5'b00101, 
		sixth=5'b00110, 
		seventh=5'b00111, 
		eighth=5'b01000,
		ack=5'b10001,   
		stop=5'b10010; 
	parameter //cnt for 4 cycles per bit
		one=2'b00,
		two=2'b01,
		three=2'b10,
		four=2'b11;
	assign sda=(link)? sda_buf:1'bz;
	
	always@(*)
	begin
		case(seq_cnt)
			2'd0:data=poweron_seq1;
			2'd1:data=poweron_seq2;
			2'd2:data=poweron_seq3;
			default:data=poweron_seq1;			
		endcase
		if(link==0)
			led=1;
		else
			led=0;
	end	
	always@(posedge clk or negedge rst)
	begin
		if(!rst or over_flag)
		begin
			en_wr<=0;
			en_wr_cnt<=0;
		end
		else if(en_wr_cnt==en_wr_cnt_max)
		begin
			en_wr<=1;
			en_wr_cnt<=0;
		end
		else if(en && !en_wr) //button pressed and en_wr!=1
			en_wr_cnt<=en_wr_cnt+1'b1;

	end
	
	always@(posedge clk or negedge rst)
	begin
		if(!rst)
		begin
			button_cnt<=10'd0;
			seq_cnt<=2'd0;
		end	
		else if(button_cnt==button_max)
		begin
			button_cnt<=2'd0;
			if(seq_cnt<2'd3)
				seq_cnt<=seq_cnt+1;
			else
				seq_cnt<=0;
		end
		else if(button)
			button_cnt<=button_cnt+1'b1;
	end
	
	always@(posedge clk or negedge rst) 
	begin
		if(!rst)
		begin
			machine_state<=machine_ini;
			over_flag<=0;
			link<=1'b0;
		end
		begin
			case(machine_state)
				machine_ini:
				begin
					i2c_state<=t_slave_addr;
					i2c_substate<=start;
					bit_cycle_cnt<=one;
					link <= 1'b0;
					if(en_wr)
						machine_state<=machine_w;
				end
				machine_w:
				begin
					case(i2c_state)
						t_slave_addr:
							case(i2c_substate)
								start:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b1;
											link <= 1'b1;//link==1 start transmission
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b0;
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b0;
											sda_buf <= 1'b0;
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= 1'b0;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= first;
										end
										default:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b1;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= start;
										end
									 endcase
								first:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[7];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[7];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[7];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[7];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= second;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[7];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= first;
										end
									 endcase
								second:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[6];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[6];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[6];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[6];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= third;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[6];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= second;
										end
									 endcase
								third:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[5];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[5];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[5];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[5];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fourth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[5];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= third;
										end
									 endcase
								fourth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[4];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[4];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[4];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[4];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fifth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[4];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fourth;
										end
									 endcase
								fifth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[3];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[3];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[3];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[3];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= sixth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[3];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fifth;
										end
									 endcase
								sixth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[2];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[2];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[2];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[2];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= seventh;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[2];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= sixth;
										end
									 endcase
								seventh:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[1];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[1];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cat_addr[1];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[1];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= eighth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[1];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= seventh;
										end
									 endcase
								eighth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= rw_cmd;
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= rw_cmd;
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= rw_cmd;
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= rw_cmd;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= ack;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= rw_cmd;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= eighth;
										end
									 endcase
								ack:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											link <= 1'b0;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											link <= 1'b0;
											sda_buf <= sda;//get the acknowledgment bit
											bit_cycle_cnt <= three;
										end	
										three:
										begin
											scl <= 1'b1;
											link <= 1'b0;
											sda_buf <= sda;
											bit_cycle_cnt <= four;
										end	
										four:
										begin
											scl <= 1'b0;
											link <= 1'b0;
											bit_cycle_cnt <= one;
											if(sda_buf == 1'b0)//ack==0 means acknowledgement is successful
											begin
												i2c_substate<=first;
												i2c_state<=command;
												link <= 1'b1;
											end
											else
											begin
												machine_state<=machine_ini;
												i2c_substate<=start;
											end
										end	
										default:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b0;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate<=ack;
										end	
									endcase
								default:machine_state<=machine_ini;
							endcase
						command:
							case(i2c_substate)
								first:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[7];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[7];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[7];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[7];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= second;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[7];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= first;
										end
									 endcase
								second:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[6];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[6];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[6];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[6];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= third;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[6];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= second;
										end
									 endcase
								third:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[5];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[5];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[5];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[5];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fourth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[5];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= third;
										end
									 endcase
								fourth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[4];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[4];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[4];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[4];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fifth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[4];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fourth;
										end
									 endcase
								fifth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[3];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[3];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[3];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[3];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= sixth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[3];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fifth;
										end
									 endcase
								sixth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[2];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[2];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[2];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[2];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= seventh;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[2];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= sixth;
										end
									 endcase
								seventh:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[1];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[1];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[1];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[1];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= eighth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[1];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= seventh;
										end
									 endcase
								eighth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[0];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[0];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= cmd[0];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[0];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= ack;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cmd[0];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= eighth;
										end
									 endcase
								ack:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											link <= 1'b0;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											link <= 1'b0;
											sda_buf <= sda;
											bit_cycle_cnt <= three;
										end	
										three:
										begin
											scl <= 1'b1;
											link <= 1'b0;
											sda_buf <= sda;
											bit_cycle_cnt <= four;
										end	
										four:
										begin
											scl <= 1'b0;
											link <= 1'b0;
											bit_cycle_cnt <= one;
											if(sda_buf == 1'b0)//ack==0 means acknowledgement is successful
											begin
												i2c_substate<=first;
												i2c_state<=data_to_port;
												link <= 1'b1;
											end
											else
											begin
												machine_state<=machine_ini;
												i2c_substate<=start;
											end
										end	
										default:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b0;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate<=ack;
										end	
									endcase
								default:machine_state<=machine_ini;
							endcase
						data_to_port:
							case(i2c_substate)
								first:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= data[7];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= data[7];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= data[7];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= data[7];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= second;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= data[7];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= first;
										end
									 endcase
								second:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= data[6];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= data[6];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= data[6];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= data[6];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= third;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= data[6];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= second;
										end
									 endcase
								third:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= data[5];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= data[5];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= data[5];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= data[5];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fourth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= data[5];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= third;
										end
									 endcase
								fourth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= data[4];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= data[4];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= data[4];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= data[4];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fifth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= data[4];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fourth;
										end
									 endcase
								fifth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= data[3];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= data[3];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= data[3];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= data[3];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= sixth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= data[3];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= fifth;
										end
									 endcase
								sixth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= data[2];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= data[2];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= data[2];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= data[2];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= seventh;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= data[2];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= sixth;
										end
									 endcase
								seventh:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= data[1];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= data[1];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= data[1];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= data[1];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= eighth;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= cat_addr[1];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= seventh;
										end
									 endcase
								eighth:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= data[0];
											link <= 1'b1;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= data[0];
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= data[0];
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b0;
											sda_buf <= data[0];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= ack;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= data[0];
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= eighth;
										end
									 endcase
								ack:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											link <= 1'b0;
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											link <= 1'b0;
											sda_buf <= sda;//get the acknowledgment bit
											bit_cycle_cnt <= three;
										end	
										three:
										begin
											scl <= 1'b1;
											link <= 1'b0;
											sda_buf <= sda;
											bit_cycle_cnt <= four;
										end	
										four:
										begin
											scl <= 1'b0;
											link <= 1'b0;									
											bit_cycle_cnt <= one;
											if(sda_buf == 1'b0)
											begin
												i2c_substate<=stop;
												link <= 1'b1;
											end
											else
											begin
												machine_state<=machine_ini;
											end
										end	
										default:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b0;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate<=ack;
										end	
									endcase
								stop:
									case(bit_cycle_cnt)
										one:
										begin
											scl <= 1'b0;
											sda_buf <= 1'b0;
											link <= 1'b1;//link==1 start transmission
											bit_cycle_cnt <= two;
										end
										two:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b0;
											link <= 1'b1;
											bit_cycle_cnt <= three;
										end
										three:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b1;
											link <= 1'b1;
											bit_cycle_cnt <= four;
										end
										four:
										begin
											scl <= 1'b1;
											sda_buf <= 1'b1;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= first;
											over_flag<=1'b1;
										end
										default:
										begin
											scl <= 1'b0;
											sda_buf <= 1'b0;
											link <= 1'b1;
											bit_cycle_cnt <= one;
											i2c_substate <= start;
										end
									endcase
								default:machine_state<=machine_ini;
							endcase
						default:machine_state<=machine_ini;
					endcase
				end
				default:machine_state<=machine_ini;
			endcase
		end	
	end
endmodule