//`timescale 1ns / 1ns

import tlul_pkg::*;
import ibex_pkg::*;
import access_control_wrapper_reg_pkg::*;
//Rename to fit Filename and Modulename
module access_control_wrapper # (
//parameter logic [31:0]		BaseAddress = 32'b0,
parameter logic [23:0]		BaseAddress = 24'b0,
parameter logic			NumPMPEntriesSelecter = 1'b0 //Default 0
) (
	input logic                    	rst,
	input logic                    	clk,
	output logic                   	irq_q,
 
	input  tlul_pkg::tl_h2d_t  	tl_h2pmp,               		//TLUL message untrusted master to wrapper (pmp)
	output tlul_pkg::tl_d2h_t       tl_pmp2h = '0,               	//error response message to untrusted master if permission denied
          
	input  tlul_pkg::tl_d2h_t	tl_d2pmp,                 		//incoming message from device to pmp, gets relayed without change
	output tlul_pkg::tl_h2d_t	tl_pmp2d = '0,               	//send message to device, if permission granted by pmp
  
	input  tlul_pkg::tl_h2d_t      	tl_cpu2csr,              		//cpu writes the cfg and address register, seperate interface for security
	output tlul_pkg::tl_d2h_t     	tl_csr2cpu = '0             	//wrapper send denied address and opcode to cpu  
);
//New address range
parameter int unsigned 		Number32BitRegisterNonPMP = 7;
parameter int unsigned 		NumberBytesRegisterNonPMP = 4*Number32BitRegisterNonPMP;
parameter int unsigned 		go_idle_addr = 0;
parameter int unsigned 		return_denied_reg_addr = 1;
parameter int unsigned 		return_denied_reg_type = 2;
parameter int unsigned 		return_current_state = 3;
parameter int unsigned 		INTR_STATE_address = 4;
parameter int unsigned		INTR_ENABLE_address = 5;
parameter int unsigned		INTR_TEST_address = 6;

//PMP parameters
parameter int unsigned          PMPNumRegions = 16;
parameter int unsigned 		AdjustedPMPNumRegions = (NumPMPEntriesSelecter) ? (PMPNumRegions << 2) : PMPNumRegions;
parameter int unsigned          PMPGranularity = 0;    
parameter int unsigned          PMPNumChan = 1;
parameter int unsigned		NumberConfigEntries =  $ceil(AdjustedPMPNumRegions/4);
parameter int unsigned		TotalIbexCSR = AdjustedPMPNumRegions + NumberConfigEntries;
parameter logic[31:0]		OneAs32Bit = 32'h00000001;


parameter int unsigned 		max_pmp_related_addr = 959;// 0 to 959 bytes->960 Bytes -> 192 32 Bit Registers (1x cfg, 4x address)
parameter int unsigned		max_bytes_addressable = 255; //1024 addressable bytes 32 bit each addressable. We don't care about byte addressable (1:0) but we implemented it
tlul_pkg::tl_d2h_t              tl_err_rsp_device_outstanding;
tlul_pkg::tl_d2h_t              tl_err_rsp_device_outstanding_q; 
tlul_pkg::tl_d2h_t              tl_err_rsp_device_outstanding_d;   
tlul_pkg::tl_d2h_t              tl_err_rsp_cpu_outstanding;

tlul_pkg::tl_d2h_t      	tl_csr2cpu_q;
tlul_pkg::tl_d2h_t      	tl_csr2cpu_d;  		

ibex_pkg::pmp_mseccfg_t         csr_pmp_mseccfg = 1'b0;
ibex_pkg::priv_lvl_e            priv_mode [PMPNumChan] = {2'b00}; 	//user mode

//PMP i/o signals
logic [33:0]             	pmp_req_addr [PMPNumChan];     
ibex_pkg::pmp_req_e  		pmp_req_type [PMPNumChan];
logic                    	pmp_req_err  [PMPNumChan];
//PMP cfg signals
ibex_pkg::pmp_cfg_t      	csr_pmp_cfg   [AdjustedPMPNumRegions];
logic [33:0]            	csr_pmp_addr  [AdjustedPMPNumRegions];
//size identifier of TL-UL address 
int				number_bits_a_mask = 0;
int				a_size_int;
int				a_size_shift_value;
//Bytewiseaddressable pmp
logic[2:0]			cpu_a_size;
//Register signals
logic [31:0]                    wr_data_csr[(TotalIbexCSR-1):0];         		//csr signals
logic [31:0]			wr_data_csr_buffer;
logic [7:0]			wr_data_csr_byte[3:0];
logic                           wr_en_csr[(TotalIbexCSR-1):0] = '{default:1'b0};
logic [31:0]                    rd_data_csr[(TotalIbexCSR-1):0];
logic [31:0]			rd_data_csr_buffer;
logic [7:0]			rd_data_csr_byte[3:0];      
logic                           rd_error_csr[(TotalIbexCSR-1):0];
logic				activate_cpu_err_resp_d = 1'b0;
logic				activate_cpu_err_resp_q;
logic [7:0]			a_data_split[3:0];   
logic [7:0]			d_data_split[3:0];
int 				constant_one = 1;
int unsigned			cpu_addr_reg_abs;
int unsigned			cpu_addr_buffer_abs;
logic                           irq_d = 1'b0;
logic[1:0]			current_state_q;
logic 		            	go_to_idle_d = 1'b0;
logic 			    	go_to_idle_q;
logic 				valid_size_matching=1'b0;
  
logic                           err_rsp_sent_d = 1'b0;
logic                           err_rsp_sent_q;

logic [7:0]                     source_id_d;
logic [7:0]                     source_id_q;  

logic [31:0]                    denied_reg_addr_d = 32'b0;
logic [31:0]                    denied_reg_addr_q = 32'b0;

logic [2:0]                     denied_reg_type_d = 3'b011;    
logic [2:0]                     denied_reg_type_q = 3'b011;
  
logic                           ack_outstanding_d;      
logic                           ack_outstanding_q;
logic				intr_from_prim_hw_intr;

logic 				INTR_STATE_d = 1'b0;
logic 				INTR_ENABLE_d= 1'b0;
logic 				INTR_TEST_d= 1'b0;

logic 				INTR_STATE_q= 1'b0;
logic 				INTR_ENABLE_q= 1'b0;
logic 				INTR_TEST_q= 1'b0;
  
logic				INTR_STATE_we= 1'b0;
logic				INTR_ENABLE_we= 1'b0;
logic				INTR_TEST_we= 1'b0;		

logic				INTR_STATE_we_d= 1'b0;
logic				INTR_ENABLE_we_d= 1'b0;
logic				INTR_TEST_we_d= 1'b0;

logic				INTR_STATE_we_q= 1'b0;
logic				INTR_ENABLE_we_q= 1'b0;
logic				INTR_TEST_we_q= 1'b0;

logic				wrong_tlul_opcode = 1'b0;
logic[31:0]			address_matching_size = 32'h00000001;

tl_d_op_e                       ack_opcode_d = 3'h0; //3 is an undefinied opcode 
tl_d_op_e                       ack_opcode_q = 3'h0; //3 is also here undefinied

//This is for debugging using symbolic pmp!
logic [3:0] Register_d;
logic [3:0] Register_q;


always_ff @(posedge clk, negedge rst) 
begin     
    if (!rst) begin                    
	Register_q <= 1'b0;
    end else begin
	Register_q <= Register_d;
    end
end

assign Register_d = Register_q;


//Interrupt-Interface
access_control_wrapper_reg2hw_t reg2hw;
access_control_wrapper_hw2reg_t hw2reg;
   
  //////////////////////////////// --instantiations
//Upec found a HW BUG, should be less than 80 register (0 to 79)
for (genvar i= 0;i<TotalIbexCSR;i++) begin : gen_pmp_csr
	ibex_csr #()
	pmp_csr (
	.clk_i(clk),
	.rst_ni(rst),
	.wr_data_i(wr_data_csr[i]),
	.wr_en_i(wr_en_csr[i]),
	.rd_data_o(rd_data_csr[i]),
	.rd_error_o(rd_error_csr[i])
	);
end
                                                                             
  ibex_pmp #(
      .PMPGranularity(PMPGranularity),
      .PMPNumChan    (PMPNumChan),
      .PMPNumRegions (AdjustedPMPNumRegions)
    ) pmp_i (
      // Interface to CSRs
      .csr_pmp_cfg_i    (csr_pmp_cfg),
      .csr_pmp_addr_i   (csr_pmp_addr),
      .csr_pmp_mseccfg_i(csr_pmp_mseccfg),
      .priv_mode_i      (priv_mode),
      // Access checking channels
      .pmp_req_addr_i   (pmp_req_addr),
      .pmp_req_type_i   (pmp_req_type),
      .pmp_req_err_o    (pmp_req_err)
    );  
   
//Implement later as Arrays. Recall them.
tlul_err_resp err_resp_wrapper (
	.clk_i(clk),
	.rst_ni(rst),
	.tl_h_i(tl_h2pmp),
	.tl_h_o(tl_err_rsp_device_outstanding)
);
tlul_err_resp cpu_error_response (
	.clk_i(clk),
	.rst_ni(rst),
	.tl_h_i(tl_cpu2csr),
	.tl_h_o(tl_err_rsp_cpu_outstanding)
);
genvar i;
generate
	for (i = 0; i < NumberConfigEntries; i = i + 1) begin : gen_csr_pmp_cfg
		assign csr_pmp_cfg[i*4] = {rd_data_csr[i][7], rd_data_csr[i][4:0]};
		assign csr_pmp_cfg[i*4 + 1] = {rd_data_csr[i][15], rd_data_csr[i][12:8]};
		assign csr_pmp_cfg[i*4 + 2] = {rd_data_csr[i][23], rd_data_csr[i][20:16]};
		assign csr_pmp_cfg[i*4 + 3] = {rd_data_csr[i][31], rd_data_csr[i][28:24]};
	end
endgenerate
generate
	for (i = 0; i < AdjustedPMPNumRegions; i = i + 1) begin : gen_csr_pmp_addr
		  assign csr_pmp_addr[i] = {rd_data_csr[i+NumberConfigEntries], 2'b0 };
		  //assign csr_pmp_addr[i] = {2'b0 ,rd_data_csr[i+NumberConfigEntries] };
	end
endgenerate

 always_comb begin
	irq_q = INTR_STATE_q & INTR_ENABLE_q;
	tl_csr2cpu.a_ready = !ack_outstanding_q & !activate_cpu_err_resp_q;
	//This might fix UPEC error
	//tl_csr2cpu = '0;
	tl_csr2cpu.d_valid = 1'b0;
	ack_outstanding_d = 1'b0;
	INTR_ENABLE_we_d = 1'b0;
	INTR_STATE_we_d = 1'b0;
	INTR_TEST_we_d = 1'b0;
	go_to_idle_d = 1'b0;
	activate_cpu_err_resp_d = 1'b0;
	wr_data_csr = '0;
	//
	a_size_shift_value[31:2] = '{30{1'b0}};
	a_size_shift_value[1:0]= tl_cpu2csr.a_size[1:0];
	a_size_int  = constant_one << a_size_shift_value;
	address_matching_size = (tl_cpu2csr.a_address &  ( a_size_int  - 1 ) );
	if (address_matching_size == 32'h0) begin
		valid_size_matching = 1'b1;
	end else begin
		valid_size_matching = 1'b0;
	end
	//valid_size_matching = &(tl_cpu2csr.a_address &&  ( ( OneAs32Bit << tl_cpu2csr.a_size) ) ) ? 1'b0 : 1'b1;
	//if (tl_cpu2csr.a_valid && tl_csr2cpu.a_ready && valid_size_matching ) begin
	if (tl_cpu2csr.a_valid && tl_csr2cpu.a_ready && valid_size_matching && (tl_cpu2csr.a_address[31:10] == BaseAddress[23:0]) ) begin
		source_id_d = tl_cpu2csr.a_source;
		//Address of config register, relative to base address of ibex csr, relative here is also absolute
		number_bits_a_mask = $countones(tl_cpu2csr.a_mask);
		//absolute address in ibex csr it's byte addressable, but we direct addressing of bytes is not supported. therefor using masking bits and PartialData
		//cpu_addr_buffer_abs = ( $unsigned(tl_cpu2csr.a_address[31:0]) - $unsigned(BaseAddress[31:0]) );
		//cpu_addr_reg_abs = {2'b0,cpu_addr_buffer_abs[31:2]};
		cpu_addr_reg_abs = {24'b0,tl_cpu2csr.a_address[9:2]};
		
		if ( (  tl_cpu2csr.a_opcode == PutFullData || tl_cpu2csr.a_opcode == PutPartialData ) && ( tl_cpu2csr.a_size == 2'b10 )  ) begin                                                                  
			
			ack_opcode_d = AccessAck;
			//Check if it's a entry for 
			if ( cpu_addr_reg_abs < Number32BitRegisterNonPMP) begin
					case (cpu_addr_reg_abs)
					
					go_idle_addr :     			begin                       	
											go_to_idle_d = 1'b1;
											ack_outstanding_d = 1'b1;
										end
					INTR_STATE_address : begin
											INTR_STATE_d = 1'b0;
											INTR_STATE_we_d = 1'b1;
											ack_outstanding_d = 1'b1;
										end
					INTR_ENABLE_address : begin
											INTR_ENABLE_d = tl_cpu2csr.a_data[31];
											INTR_ENABLE_we_d = 1'b1;
											ack_outstanding_d = 1'b1;
										end
					INTR_TEST_address : begin
											INTR_TEST_d = tl_cpu2csr.a_data[31];
											INTR_TEST_we_d = 1'b1;
											ack_outstanding_d = 1'b1;
										end
					default: 				begin
											activate_cpu_err_resp_d = 1'b1;
										end 
					endcase
			end else if ( cpu_addr_reg_abs < (Number32BitRegisterNonPMP + TotalIbexCSR) ) begin
				wr_data_csr[cpu_addr_reg_abs - Number32BitRegisterNonPMP] = tl_cpu2csr.a_data;
				wr_en_csr[cpu_addr_reg_abs - Number32BitRegisterNonPMP] = 1'b1;
				ack_outstanding_d = 1'b1;
			end else begin
				activate_cpu_err_resp_d = 1'b1;
			end
		//Here we have a actual PartialData, Specification of TileLink 4.6 Byte Lanes indicates that there are no spaces between active byte lanes
		//For now we allow it here to address with inactive bytelanes between active bytelanes
		//previous implementation
		//end else if ( ( tl_cpu2csr.a_opcode == PutPartialData ) && ( ( tl_cpu2csr.a_size < 2'b10 ) ) && ( number_bits_a_mask == a_size_int ) ) begin
		end else if ( ( tl_cpu2csr.a_opcode == PutPartialData ) && ( ( tl_cpu2csr.a_size < 2'b10 ) ) ) begin
			//Check if the byte addressing is correct. If the length of the data +  start byte of the data exceeds max bytes supported, we return an error.
			ack_opcode_d = AccessAck;
			if ( cpu_addr_reg_abs < Number32BitRegisterNonPMP )begin
				case (cpu_addr_reg_abs)
					
					go_idle_addr :     begin                       			//addr 0, 4 cfg registers
											go_to_idle_d = 1'b1;
											ack_outstanding_d = 1'b1;
										end
					INTR_STATE_address : begin
											INTR_STATE_d = 1'b0;
											INTR_STATE_we_d = 1'b1;
											ack_outstanding_d = 1'b1;
										end
					INTR_ENABLE_address : begin
											INTR_ENABLE_d = tl_cpu2csr.a_data[31];
											INTR_ENABLE_we_d = 1'b1;
											ack_outstanding_d = 1'b1;
										end
					INTR_TEST_address : begin
											INTR_TEST_d = tl_cpu2csr.a_data[31];
											INTR_TEST_we_d = 1'b1;
											ack_outstanding_d = 1'b1;
										end
					default: 				begin
											//tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
											activate_cpu_err_resp_d = 1'b1;
										end 
				endcase
			end else if ( cpu_addr_reg_abs < (Number32BitRegisterNonPMP + TotalIbexCSR) ) begin
				rd_data_csr_buffer = rd_data_csr[cpu_addr_reg_abs - Number32BitRegisterNonPMP];
				for (int i = 0; i <= 3; i++) begin      		//set write enables to 0 after every op
					wr_data_csr_byte[i] = tl_cpu2csr.a_mask[i] ? tl_cpu2csr.a_data[(8*i+7):(8*i)] : rd_data_csr_buffer[(8*i+7):(8*i)];
				end

				wr_data_csr[cpu_addr_reg_abs - Number32BitRegisterNonPMP] = {wr_data_csr_byte[3],wr_data_csr_byte[2],wr_data_csr_byte[1],wr_data_csr_byte[0]};
				wr_en_csr[cpu_addr_reg_abs - Number32BitRegisterNonPMP] = 1'b1;
				ack_outstanding_d = 1'b1;
			end else begin
				activate_cpu_err_resp_d = 1'b1;
			end
		
		//For this case we need to pass csr2cpu through a register, to be able to send it in the next clock cycle.
		end else if (tl_cpu2csr.a_opcode == Get && ( number_bits_a_mask == a_size_int ) ) begin 
			ack_opcode_d = AccessAckData;
			if ( cpu_addr_reg_abs < Number32BitRegisterNonPMP ) begin
				case (cpu_addr_reg_abs)
				//29'b00000000000000000000000010100 :     begin                       			//addr 0, 4 cfg registers
				return_denied_reg_addr : begin
										tl_csr2cpu_d.d_data = denied_reg_addr_q;
										ack_outstanding_d = 1'b1;
									end
				//29'b00000000000000000000000011000 :     begin                       			//addr 0, 4 cfg registers
				return_denied_reg_type : begin
										tl_csr2cpu_d.d_data[2:0] = denied_reg_type_q;
										tl_csr2cpu_d.d_data[31:3] = '{29{1'b0}};
										ack_outstanding_d = 1'b1;
									end
				//29'b00000000000000000000000011001 :     begin                       			//addr 0, 4 cfg registers
				return_current_state : begin
										//tl_csr2cpu.d_data = {'{31{1'b0}} , current_state };
										tl_csr2cpu_d.d_data[1:0] = current_state;
										tl_csr2cpu_d.d_data[31:2] = '{30{1'b0}};
										ack_outstanding_d = 1'b1;
									end
				INTR_STATE_address : 			begin
										tl_csr2cpu_d.d_data[31] = INTR_STATE_q;
										tl_csr2cpu_d.d_data[30:0] = '{31{1'b0}};
										ack_outstanding_d = 1'b1;
									end
				INTR_ENABLE_address : 			begin
										tl_csr2cpu_d.d_data[31] = INTR_ENABLE_q;
										tl_csr2cpu_d.d_data[30:0] = '{31{1'b0}};
										ack_outstanding_d = 1'b1;
									end
				default: 				begin
										//tl_csr2cpu = tl_err_rsp_cpu_outstanding;
										activate_cpu_err_resp_d = 1'b1;
									end 
				endcase
			end else if ( cpu_addr_reg_abs < ( Number32BitRegisterNonPMP + TotalIbexCSR) ) begin
				tl_csr2cpu_d.d_data = rd_data_csr[cpu_addr_reg_abs - Number32BitRegisterNonPMP];
				ack_outstanding_d = 1'b1;
			end else begin
				//if tl_cpu2csr.a_addres[31] == False we know that it's 00 (wrapper related ) or 11 (pmp config related)
				//tl_csr2cpu = tl_err_rsp_cpu_outstanding;
				activate_cpu_err_resp_d = 1'b1;
			end
		//Invalid opcode, return error.
		end else begin
			//tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
			activate_cpu_err_resp_d = 1'b1;
		end
	end else begin
		activate_cpu_err_resp_d = 1'b1;
	end
	
	if (ack_outstanding_q) begin
		//set write enables to 0 after every op
		for (int i=0;i< TotalIbexCSR ;i++) begin
			wr_en_csr[i] = 1'b0;
		end
		number_bits_a_mask = 0;
	end
	if (!INTR_ENABLE_we_d) begin
		INTR_ENABLE_d = INTR_ENABLE_q;
	end
	if (irq_d) begin
		INTR_STATE_d = 1'b1;
	end else begin
		if (INTR_STATE_we_d) begin
			INTR_STATE_d = 1'b0;
		end else begin
			INTR_STATE_d = INTR_STATE_q;
		end
	end
	if (!INTR_TEST_we_d) begin
		INTR_TEST_d = INTR_TEST_q;
	end
	if (tl_cpu2csr.d_ready && activate_cpu_err_resp_q) begin
		tl_csr2cpu.d_data = tl_err_rsp_cpu_outstanding.d_data;
		tl_csr2cpu.d_opcode = tl_err_rsp_cpu_outstanding.d_opcode;
		tl_csr2cpu.d_source = tl_err_rsp_cpu_outstanding.d_source;
		tl_csr2cpu.d_param = tl_err_rsp_cpu_outstanding.d_param;
		tl_csr2cpu.d_size = tl_err_rsp_cpu_outstanding.d_size;
		tl_csr2cpu.d_sink = tl_err_rsp_cpu_outstanding.d_sink;
		tl_csr2cpu.d_user = tl_err_rsp_cpu_outstanding.d_user;
		tl_csr2cpu.d_error = tl_err_rsp_cpu_outstanding.d_error;
		tl_csr2cpu.d_valid = 1'b1;
		activate_cpu_err_resp_d = 1'b0;
		ack_outstanding_d = 1'b0;
	end else if (tl_cpu2csr.d_ready && ack_outstanding_q) begin                     
		tl_csr2cpu.d_source = source_id_q;
		tl_csr2cpu.d_opcode = ack_opcode_q;
		tl_csr2cpu.d_valid = 1'b1;
		tl_csr2cpu.d_data = tl_csr2cpu_q.d_data;
		tl_csr2cpu.d_size = 2'b10;
		tl_csr2cpu.d_error = 1'b0;
		ack_outstanding_d = 1'b0;
		
	end else if (!tl_cpu2csr.d_ready && ack_outstanding_q) begin
		ack_outstanding_d = ack_outstanding_q;
	end
end

//logic event_intr_rise, event_intr_fall, event_intr_actlow, event_intr_acthigh;
logic junk_state_de,junk_state_d;
logic INTR_TEST_q_all_one;

assign INTR_TEST_q_all_one = &INTR_TEST_q;


  ////////////////////////////////  --flip flop internal signals
  
  always_ff @(posedge clk, negedge rst) begin     
    if (!rst) begin                    
	source_id_q <= 0;
	err_rsp_sent_q <= 0;
	ack_opcode_q <= 3'h3;
	ack_outstanding_q <= 0;
	denied_reg_addr_q <= 0;
	denied_reg_type_q <= 0;
	go_to_idle_q <= 0;
	denied_reg_type_q <= 0;
	wr_en_csr <= {1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
	activate_cpu_err_resp_q <= 1'b0;
	tl_csr2cpu_q <= '0;//VHDL syntax (others => '0') (all 0)
	//pmp_reg_err_q <= 1'b0;
	tl_err_rsp_device_outstanding_q <= '0;
	INTR_STATE_q <= 1'b0;
	INTR_ENABLE_q <= 1'b0;
	INTR_TEST_q <= 1'b0;
	INTR_STATE_we_q <= 1'b0;
	INTR_ENABLE_we_q <= 1'b0;
	INTR_TEST_we_q <= 1'b0;
    end else begin
	ack_opcode_q <= ack_opcode_d;
	source_id_q <= source_id_d;
	err_rsp_sent_q <= err_rsp_sent_d;  
	ack_outstanding_q <= ack_outstanding_d;
	denied_reg_addr_q <= denied_reg_addr_d;
	denied_reg_type_q <= denied_reg_type_d;
	go_to_idle_q <= go_to_idle_d;
	//denied_reg_type_q <= denied_reg_type_d;
	tl_csr2cpu_q <= tl_csr2cpu_d;
	activate_cpu_err_resp_q <= activate_cpu_err_resp_d;
	//pmp_reg_err_q[0] <= pmp_reg_err_d[0];
	//tl_err_rsp_device_outstanding_q <= tl_err_rsp_device_outstanding_d;
	INTR_STATE_q <= INTR_STATE_d;
	INTR_ENABLE_q <= INTR_ENABLE_d;
	INTR_TEST_q <= INTR_TEST_d;
	INTR_STATE_we_q <= INTR_STATE_we_d;
	INTR_ENABLE_we_q <= INTR_ENABLE_we_d;
	INTR_TEST_we_q <= INTR_TEST_we_d;
    end
  end
  
  ////////////////////////////////  --fsm

//enum logic {idle = 1'b0, block = 1'b1} current_state, next_state;
enum logic[1:0] {idle = 2'b00, block_start = 2'b01, block_idle = 2'b10, block_err = 2'b11} current_state, next_state;
assign current_state_q = current_state;
always_ff @(posedge clk, negedge rst) begin
	if(!rst) begin                      
		current_state <= idle;
	end else begin		
		current_state <= next_state;
	end
end
  
  
  always_comb begin
	irq_d = 1'b0;
	wrong_tlul_opcode = 1'b0;
	tl_pmp2d ='0;
	if (tl_h2pmp.a_opcode == 3'h0 || tl_h2pmp.a_opcode == 3'h1) begin
		pmp_req_type [0] = PMP_ACC_WRITE;  			
	end else if (tl_h2pmp.a_opcode == 3'h4) begin
		pmp_req_type [0] = PMP_ACC_READ; 			
	end /*else begin
		wrong_tlul_opcode = 1'b1;
		//That might be exec or write, but ibex_pmp requires it to be set to any value.
		// to avoid pmp_req_err to become X, we define it as EXEC here.
		pmp_req_type [0] = PMP_ACC_EXEC;
	end*/
    case(current_state)                  
              
      idle :	begin
			next_state = idle;
			//tl_pmp2d.d_ready = tl_h2pmp.d_ready;             
			tl_pmp2h = tl_d2pmp;
			if (tl_h2pmp.a_valid && tl_d2pmp.a_ready) begin 
				pmp_req_addr [0] = {2'b0,tl_h2pmp.a_address};
				
				//pmp_req_addr [0] = {tl_h2pmp.a_address, 2'b0};
				
				if (pmp_req_err[0] || wrong_tlul_opcode) begin                                            
					next_state = block_start;
					tl_pmp2d.a_valid = 1'b0;
					//Added to fullfil spec
					tl_pmp2d.d_ready = tl_h2pmp.d_ready;
					denied_reg_addr_d = tl_h2pmp.a_address;
					denied_reg_type_d = tl_h2pmp.a_opcode;
					irq_d = 1'b1;
					//pmp_reg_err_d[0] =1'b1;
				end else begin 
					//if () begin
					tl_pmp2d = tl_h2pmp;
					//end else begin
						
					//end
				end  
			end
	      end                                                   
	block_start:
		begin
			//tl_pmp2d.a_valid = 1'b0;
			//Next step is to get rid off pmp_reg_err_q
			/*
			if(pmp_reg_err_q[0]) begin
				pmp_reg_err_d[0] =1'b0;
				tl_err_rsp_device_outstanding_d = tl_err_rsp_device_outstanding;
			end else begin
				tl_err_rsp_device_outstanding_d = tl_err_rsp_device_outstanding_q;
			end
			*/
			// For now we keep this if construct.
			//For later we consider adding an additional internal signal pmp_reg_err_mux_q
			//this signal represents the output of a multiplexer, which desides between tl_err_rsp_device_outstanding(_q)
			tl_pmp2h.d_opcode = tl_err_rsp_device_outstanding.d_opcode;
			tl_pmp2h.d_param = tl_err_rsp_device_outstanding.d_param ;
			tl_pmp2h.d_size = tl_err_rsp_device_outstanding.d_size;
			tl_pmp2h.d_source = tl_err_rsp_device_outstanding.d_source;
			tl_pmp2h.d_sink = tl_err_rsp_device_outstanding.d_sink;
			tl_pmp2h.d_data = tl_err_rsp_device_outstanding.d_data ;
			tl_pmp2h.d_user = tl_err_rsp_device_outstanding.d_user;
			tl_pmp2h.d_error = tl_err_rsp_device_outstanding.d_error;
			tl_pmp2h.d_valid = 1'b1;
			tl_pmp2h.a_ready = 1'b0;
			if (tl_h2pmp.d_ready & go_to_idle_d) begin
				next_state = idle;
				tl_pmp2d.d_ready = tl_h2pmp.d_ready;
			end else if (!tl_h2pmp.d_ready & go_to_idle_d) begin
				next_state = block_idle;
			end else if (tl_h2pmp.d_ready & !go_to_idle_d) begin
				next_state = block_err;
				tl_pmp2d.d_ready = tl_h2pmp.d_ready;
			end else if (!tl_h2pmp.d_ready & !go_to_idle_d) begin
				next_state = block_start;				
			end
			tl_pmp2d.a_valid = 1'b0;
			tl_pmp2d.d_ready = 1'b0;
		end
	block_idle:
		begin
			if(tl_h2pmp.d_ready) begin
				next_state = idle;
				tl_pmp2d.d_ready = tl_h2pmp.d_ready;
			end else begin
				next_state = block_idle;
				tl_pmp2d.d_ready = 1'b0;
			end
			tl_pmp2d.a_valid = 1'b0;
			
			tl_pmp2h.d_valid = 1'b1;
			tl_pmp2h.d_opcode = tl_err_rsp_device_outstanding.d_opcode;
			tl_pmp2h.d_param = tl_err_rsp_device_outstanding.d_param;
			tl_pmp2h.d_size = tl_err_rsp_device_outstanding.d_size;
			tl_pmp2h.d_source = tl_err_rsp_device_outstanding.d_source;
			tl_pmp2h.d_sink = tl_err_rsp_device_outstanding.d_sink;
			tl_pmp2h.d_data = tl_err_rsp_device_outstanding.d_data;
			tl_pmp2h.d_user = tl_err_rsp_device_outstanding.d_user;
			tl_pmp2h.d_error = tl_err_rsp_device_outstanding.d_error;
			tl_pmp2h.a_ready = 1'b0;
		end

	block_err:
		begin
			
			tl_pmp2h = tl_d2pmp;
			tl_pmp2h.d_opcode = tl_d2pmp.d_opcode;
			tl_pmp2h.d_param = tl_d2pmp.d_param;
			tl_pmp2h.d_size = tl_d2pmp.d_size;
			tl_pmp2h.d_source = tl_d2pmp.d_source;
			tl_pmp2h.d_sink = tl_d2pmp.d_sink;
			tl_pmp2h.d_data = tl_d2pmp.d_data;
			tl_pmp2h.d_user = tl_d2pmp.d_user;
			tl_pmp2h.d_error = tl_d2pmp.d_error;
			if(go_to_idle_d) begin
				next_state = idle;
				//go_to_idle_d = 1'b0;
				//Found that with UPEC; add this to the corresponding section.
				// Dino:This might be security critical
				//tl_pmp2d = tl_h2pmp;
				tl_pmp2h.a_ready = tl_d2pmp.a_ready;
			end else begin
				next_state = block_err;
				tl_pmp2d.a_valid = 1'b0;
				
				tl_pmp2h.a_ready = 1'b0;
			end
			tl_pmp2d.d_ready = tl_h2pmp.d_ready;
		end
    endcase
  end
endmodule
  
  
  
 
