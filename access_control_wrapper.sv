//`timescale 1ns / 1ns

import tlul_pkg::*;
import ibex_pkg::*;
//Rename to fit Filename and Modulename
module access_control_wrapper(

input logic                    	rst,
input logic                    	clk,
output logic                   	irq_q,
 
input  tlul_pkg::tl_h2d_t  	tl_h2pmp,               		//TLUL message untrusted master to wrapper (pmp)
output tlul_pkg::tl_d2h_t       tl_pmp2h = '0,               	//error response message to untrusted master if permission denied
          
input  tlul_pkg::tl_d2h_t	tl_d2pmp,                 		//incoming message from device to pmp, gets relayed without change
output tlul_pkg::tl_h2d_t	tl_pmp2d = '0,               	//send message to device, if permission granted by pmp
  
input  tlul_pkg::tl_h2d_t      	tl_cpu2csr,              		//cpu writes the cfg and address register, seperate interface for security
output tlul_pkg::tl_d2h_t      	tl_csr2cpu = '0             	//wrapper send denied address and opcode to cpu  
  );
//TileLink UL identifier for writting PMP config
parameter bit 			TL_UL_PMP_CFG = 2'b11;

  //PMP parameters
parameter int unsigned          PMPGranularity = 0;    
parameter int unsigned          PMPNumChan = 1;
parameter int unsigned          PMPNumRegions = 4;     		//n+(n/4) registers for n regions, max is 4*2^29=2^31
parameter int signed		NumberConfigEntries =  $ceil(PMPNumRegions/4);
parameter int signed		NumberIbexCfgRegister
tlul_pkg::tl_d2h_t              tl_err_rsp_device_outstanding;   
tlul_pkg::tl_d2h_t              tl_err_rsp_cpu_outstanding;

tlul_pkg::tl_d2h_t      	tl_csr2cpu_q;
tlul_pkg::tl_d2h_t      	tl_csr2cpu_d;  		
  
ibex_pkg::pmp_mseccfg_t           csr_pmp_mseccfg = 1'b0;
ibex_pkg::priv_lvl_e              priv_mode [PMPNumChan] = {2'b00}; 	//user mode

//PMP i/o signals
logic [33:0]             	        pmp_req_addr [PMPNumChan];     
ibex_pkg::pmp_req_e      	        pmp_req_type [PMPNumChan];
logic                    	        pmp_req_err  [PMPNumChan];
  
//PMP cfg signals
ibex_pkg::pmp_cfg_t      	        csr_pmp_cfg   [PMPNumRegions];
logic [33:0]            	        csr_pmp_addr  [PMPNumRegions];
//size identifier of TL-UL address 
int 				    	cpu_addr_rel_int;
int				    	number_bits_a_mask;
int				    	a_size_int;
//Bytewiseaddressable pmp
logic [1:0]			pmp_byte_sel;
//Register signals
logic [31:0]                      wr_data_csr[4:0];         		//csr signals
logic                             wr_en_csr[4:0] = {0, 0, 0, 0, 0};
logic [31:0]                      rd_data_csr[4:0];      
logic                             rd_error_csr[4:0];
   
logic [28:0]                       cpu_addr_rel;

logic                             irq_d = 1'b0;

logic 		            go_to_idle_d = 1'b0;
logic 			    go_to_idle_q;
  
logic                             err_rsp_sent_d = 1'b0;
logic                             err_rsp_sent_q;

logic [7:0]                       source_id_d;
logic [7:0]                       source_id_q;  

logic [31:0]                      denied_req_addr_d = 0;
logic [31:0]                      denied_req_addr_q;

logic [2:0]                       denied_req_type_d = 0;    
logic [2:0]                       denied_req_type_q;
  
logic                             ack_outstanding_d = 0;      
logic                             ack_outstanding_q;
  
tl_d_op_e                         ack_opcode_d;
tl_d_op_e                         ack_opcode_q;
   
  //////////////////////////////// --instantiations
  
  ibex_csr pmp_csr[4:0] (                                   		//instantiate cs registers for pmp
    .clk_i(clk),                                            		//register 0 -> pmp cfg 0-3
    .rst_ni(rst),                                           		//register 1-4 -> pmp address 0-3
    .wr_data_i(wr_data_csr),                                		//register 5 -> hold denied address for irq
    .wr_en_i(wr_en_csr),                                    		//register 6 -> hold denied opcode for irq
    .rd_data_o(rd_data_csr),                            
    .rd_error_o(rd_error_csr)
  ); 
                                                                                
  ibex_pmp #(
      .PMPGranularity(PMPGranularity),
      .PMPNumChan    (PMPNumChan),
      .PMPNumRegions (PMPNumRegions)
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

tlul_err_resp cpu_error_response (
	.clk_i(clk),
	.rst_ni(rst),
	.tl_h_i(tl_cpu2csr),
	.tl_h_o(tl_err_rsp_cpu_outstanding)
  );
  
  ////////////////////////////////  --assignements
  //Make them generic afterwards.
  //First fix the wiring mistakes and verify them
  //Afterwards find a scheme and implement it generic
  assign csr_pmp_cfg[0] = {rd_data_csr[0][7],rd_data_csr[0][4:0]};
  assign csr_pmp_cfg[1] = {rd_data_csr[0][15],rd_data_csr[0][12:8]};
  assign csr_pmp_cfg[2] = {rd_data_csr[0][23],rd_data_csr[0][20:16]};
  assign csr_pmp_cfg[3] = {rd_data_csr[0][31],rd_data_csr[0][28:24]};
  assign csr_pmp_addr[0] = rd_data_csr[1];
  assign csr_pmp_addr[1] = rd_data_csr[2];
  assign csr_pmp_addr[2] = rd_data_csr[3];
  assign csr_pmp_addr[3] = rd_data_csr[4];
assign 	tl_csr2cpu = 	tl_csr2cpu_q;
  
  ////////////////////////////////  -- CPU Interface
// ERROR RESPONSE
//We might consider opentitan.org/book/hw/ip/tlul/index.html#explicit-error-cases as default check for errors.
//We basically use the error response unit for each interface (cpu2csr vv + h2d vv
//Check lowRISC/opentitan/blob/master/hw/ip/tlul_socket_1n.sv for example of including

//Discussion of CPU-Interface
//We have atleast 32 bit address range; we consider 64 bit address range later.
//We assume byte addressable, for now we only implement 4 byte package and change the range of address to this scheme.
//For now we reserve the  6 least significant bits for special cases.
//PMP supports up to 64 Config register (8 bit each) -> 16*32 bit register , with byte addressable we have again 64 address->6 bits
//Each address written to PMP is 32 bit long. We have a total of 64 entries. They have to be byte addressable, therefor we need 256*8bit -> 8bits
//Total number of 20 Bits out of 32 Bits available for addressspace
//Reservation of Address: MaskSpecialCases: 0x0000 003F MaskPMPConfig: 0x0000 3FC0 MaskPMPEntry: 0x003F C000tl_cpu2csr
 always_comb begin 
  
	tl_csr2cpu.a_ready = !ack_outstanding_q;
  
	if (tl_cpu2csr.a_valid && tl_csr2cpu.a_ready) begin                    
		ack_outstanding_d = 1'b1;   
		source_id_d = tl_cpu2csr.a_source;
		//cpu address relative to base address of 
		cpu_addr_rel = tl_cpu2csr.a_address[28:0];
		//Not sure if conversion to int is actually necessary, because MSB is 0 anyways.
		//cpu_addr_rel_int = int'({3b'000,cpu_addr_rel});
		cpu_addr_rel_int = {3b'000,cpu_addr_rel};
		//reasearch: popcount is not synthesizable. Therefor using $countbits(data,'1);
		//number_bits_a_mask = popcount(tl_cpu2csr.a_mask);
		number_bits_a_mask = $countbits(tl_cpu2csr.a_mask,'1);
		pmp_byte_sel = tl_cpu2csr.a_address[30:29];
		//2^(a_size) wie might implement this a bit more efficient
		//a_size_int = int'( 2 ** int'(tl_cpu2csr.a_size) );
		//Shift 32d'1 by the integer value of a_size (for 32 bit bus it's 2 bit in size, therefor we net to extend by 30 0s)
		a_size_int  = {'{31{1b'0}},1b'1} << ( {'{30{1b'0}},tl_cpu2csr.a_size} );
		//For now PutFullData is implemented
		if (tl_cpu2csr.a_opcode == PutFullData && ( tl_cpu2csr.a_size == 2'b10 ) && ( tl_cpu2csr.a_mask == 4b'1111 )) begin                                                                  
			ack_opcode_d = AccessAck;
			//a_address bit 31 indicates writting to pmp address; 30to29 is byt offset,for fulldatawe don't expect it.
			if (tl_cpu2csr.a_address[31] == 1b'1 && ( cpu_addr_rel_int < PMPNumRegions ) ) begin
				//Now we have to take a_size and a_mask into account
				wr_data_csr[cpu_addr_rel_int + NumberConfigEntries] = tl_cpu2csr.a_data;
				wr_en_csr[cpu_addr_rel_int + NumberConfigEntries] = 1'b1;
			end else begin
				//if tl_cpu2csr.a_addres[31] == False we know that it's 00 (wrapper related ) or 11 (pmp config related)
				if (tl_cpu2csr.a_address[30:29] == 2b'00) begin
					case (cpu_addr_rel)
					
					29'b00000000000000000000000000000 :     begin                       			//addr 0, 4 cfg registers
											go_to_idle_d = 1;
										end
					default: 				begin
											tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
										end 
					endcase
				end else if (tl_cpu2csr.a_address[30:29] == 2b'11) begin
					//cast cpu_addr_rel to int
					
					//we just care about [28:2] because we don't address bytewise
					//check 
					// NumberConfigEntries = ceil(PMPNumRegions/4)
					if ( cpu_addr_rel_int < NumberConfigEntries ) begin
						wr_data_csr[cpu_addr_rel_int] = tl_cpu2csr.a_data;
						wr_en_csr[cpu_addr_rel_int] = 1'b1;
					end else begin
						tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
					end
				end else begin
					tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
				end
		//Here we check if PutPartialData is actually 32 bit wide (same like PutFullData)
		end else if ((tl_cpu2csr.a_opcode == PutPartialData) && ( tl_cpu2csr.a_size == 2'b10 ) && ( tl_cpu2csr.a_mask == 4b'1111 ) ) begin                                                                  
			ack_opcode_d = AccessAck;
			//Case for checking if it's writting pmp address
			//For PartialData we care about [30:29] (Byte-Offset) for FullData we don't care
			if (tl_cpu2csr.a_address[31] == 1b'1 && ( cpu_addr_rel_int < PMPNumRegions ) ) begin
				wr_data_csr[cpu_addr_rel_int + NumberConfigEntries] = tl_cpu2csr.a_data;
				wr_en_csr[cpu_addr_rel_int + NumberConfigEntries] = 1'b1;
			end else begin
				//if tl_cpu2csr.a_addres[31] == False we know that it's 00 (wrapper related ) or 11 (pmp config related)
				if (tl_cpu2csr.a_address[30:29] == 2b'00) begin
					case (cpu_addr_rel)
					
					29'b00000000000000000000000000000 :     begin                       			//addr 0, 4 cfg registers
											go_to_idle_d = 1;
										end
					default: 				begin
											tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
										end 
					endcase
				end else if (tl_cpu2csr.a_address[30:29] == 2b'11) begin
					//cast cpu_addr_rel to int
					
					//we just care about [28:2] because we don't address bytewise
					//check 
					// NumberConfigEntries = ceil(PMPNumRegions/4)
					if ( cpu_addr_rel_int < NumberConfigEntries ) begin
						wr_data_csr[cpu_addr_rel_int] = tl_cpu2csr.a_data;
						wr_en_csr[cpu_addr_rel_int] = 1'b1;
					end else begin
						tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
					end
				end else begin
					tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
				end
			end
		//Here we have a actual PartialData, Specification of TileLink 4.6 Byte Lanes indicates that there are no spaces between active byte lanes
		end else if ( ( tl_cpu2csr.a_opcode == PutPartialData ) && ( ( tl_cpu2csr.a_size < 2'b10 ) ) && ( number_bits_a_mask == a_size_int ) ) begin
			//Check if the byte addressing is correct. If the length of the data +  start byte of the data exceeds max bytes supported, we return an error.
			if ( {'{30{1b'0}},pmp_byte_sel} + a_size_int <= 4 ) begin
				ack_opcode_d = AccessAck;
				//Case for checking if it's writting pmp address
				//For PartialData we care about [30:29] (Byte-Offset) for FullData we don't care
				if (tl_cpu2csr.a_address[31] == 1b'1) begin
					
					// we write 2 or 1 byte
					//Here we have to take into account that we transmit a byte offset with the a_address
					
						for (int i = 0; i <= 3; i++) begin                		//set write enables to 0 after every op
							if ( tl_cpu2csr.a_mask[i] == 1'b1) begin
								wr_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)] = tl_cpu2csr.a_data[( ( 8*( i+1 ) ) -1 ):(8*i)];
							end else begin
								wr_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)] = rd_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)]
							end
						wr_en_csr[cpu_addr_rel_int + NumberConfigEntries] = 1'b1;
						end
					end
				end else begin
					//if tl_cpu2csr.a_addres[31] == False we know that it's 00 (wrapper related ) or 11 (pmp config related)
					if (tl_cpu2csr.a_address[30:29] == 2b'00) begin
						case (cpu_addr_rel)
						
						29'b00000000000000000000000000000 :     begin                       			//addr 0, 4 cfg registers
												go_to_idle_d = 1;
											end
						default: 				begin
												tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
											end 
						endcase
					end else if (tl_cpu2csr.a_address[30:29] == 2b'11) begin
						//cast cpu_addr_rel to int
						
						//we just care about [28:2] , the bus supports bytewise, therefor [1:0] is used in this case.
						//check 
						// NumberConfigEntries = ceil(PMPNumRegions/4)
						for (int i = 0; i <= 3; i++) begin                		//set write enables to 0 after every op
							if ( tl_cpu2csr.a_mask[i] == 1'b1) begin
								wr_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)] = tl_cpu2csr.a_data[( ( 8*( i+1 ) ) -1 ):(8*i)];
							end else begin
								wr_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)] = rd_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)]
							end
						end
						wr_en_csr[cpu_addr_rel_int] = 1'b1;
					end else begin
						tl_csr2cpu_d = tl_err_rsp_cpu_outstanding; 
					end
				end
			//size is too long, return error.
			end else begin
				tl_csr2cpu_d = tl_err_rsp_cpu_outstanding; 
			end

		end else if (tl_cpu2csr.a_opcode == Get) begin                                        
			ack_opcode_d = AccessAckData;
			if (tl_cpu2csr.a_address[31] == 1b'1)
				// we write 2 or 1 byte
				for (int i = 0; i <= 3; i++) begin                		//set write enables to 0 after every op
					if ( tl_cpu2csr.a_mask[i] == 1'b1) begin
						wr_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)] = tl_cpu2csr.a_data[( ( 8*( i+1 ) ) -1 ):(8*i)];
					end else begin
						wr_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)] = rd_data_csr[cpu_addr_rel_int + NumberConfigEntries][( ( 8*( i+1 ) ) -1 ):(8*i)]
					end
				wr_en_csr[cpu_addr_rel_int + NumberConfigEntries] = 1'b1;
				end
			end else begin
				//if tl_cpu2csr.a_addres[31] == False we know that it's 00 (wrapper related ) or 11 (pmp config related)
				if (tl_cpu2csr.a_address[30:29] == 2b'00) begin
					case (cpu_addr_rel)
					
					29'b00000000000000000000000000000 :     begin                       			//addr 0, 4 cfg registers
											go_to_idle_d = 1;
										end
					default: 				begin
											$display("Nothing done! This case isn't implemented yet");
										end 
					endcase
				end else if (tl_cpu2csr.a_address[30:29] == 2b'11) begin
					//cast cpu_addr_rel to int
					
					//we just care about [28:2] because we don't address bytewise
					//check 
					// NumberConfigEntries = ceil(PMPNumRegions/4)
					for (int i = 0; i <= 3; i++) begin                		//set write enables to 0 after every op
						if ( tl_cpu2csr.a_mask[i] == 1'b1) begin
							wr_data_csr[cpu_addr_rel_int + number_config_entries][( ( 8*( i+1 ) ) -1 ):(8*i)] = tl_cpu2csr.a_data[( ( 8*( i+1 ) ) -1 ):(8*i)];
						end else begin
							wr_data_csr[cpu_addr_rel_int + number_config_entries][( ( 8*( i+1 ) ) -1 ):(8*i)] = rd_data_csr[cpu_addr_rel_int + number_config_entries][( ( 8*( i+1 ) ) -1 ):(8*i)]
						end
					end
				end else begin
					tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
				end
			end
		//Invalid opcode, return error.
		end else begin
			tl_csr2cpu_d = tl_err_rsp_cpu_outstanding;
		end
	end
end 
+
          		//set write enables to 0 after every op
        wr_en_csr[i] = 1'b0;-+
      end
      
      if (tl_cpu2csr.d_ready) begin                     
        tl_csr2cpu.d_source = source_id_q;
        tl_csr2cpu.d_opcode = ack_opcode_q;
        tl_csr2cpu.d_valid = 1'b1;
        ack_outstanding_d = 1'b0;
      end
      
    end else if (!ack_outstanding_q) begin
      tl_csr2cpu.d_valid = 1'b0;
    end
    
  end
 
  logic denied_addr_read_d, denied_addr_read_q;
  logic denied_req_type_read_d, denied_req_type_read_q;

  ////////////////////////////////  --flip flop internal signals
  
  always_ff @(posedge clk, negedge rst) begin     
    if (!rst) begin                    
      source_id_q <= 0;
      err_rsp_sent_q <= 0;
      irq_q <= 0;
      ack_outstanding_q <= 0;
      denied_req_addr_q <= 0;
      denied_req_type_q <= 0;
      go_to_idle_q <= 0;
      denied_addr_read_q <= 0;
      denied_req_type_q <= 0;
	wr_en_csr <= 5'b00000;
	tl_csr2cpu_q <= '{32{1'b0}};//VHDL syntax (others => '0') (all 0)
    end else begin
      ack_opcode_q <= ack_opcode_d;
      source_id_q <= source_id_d;
      err_rsp_sent_q <= err_rsp_sent_d;
      irq_q <= irq_d;   
      ack_outstanding_q <= ack_outstanding_d;
      denied_req_addr_q <= denied_req_addr_d;
      denied_req_type_q <= denied_req_type_d;
      go_to_idle_q <= go_to_idle_d;
      denied_addr_read_q <= denied_addr_read_d;
      denied_req_type_q <= denied_req_type_d;
      tl_csr2cpu_q <= tl_csr2cpu_d;
    end
  end
  
  ////////////////////////////////  --fsm
  
  enum logic {idle = 1'b0, block = 1'b1} current_state, next_state;
  
  always_ff @(posedge clk, negedge rst) begin
    if(!rst) begin                      
      current_state <= idle;
      end
    else begin		
      current_state <= next_state;
      end
  end
  
  
  always_comb begin
    case(current_state)                  
              
      idle :       begin
                      next_state = idle;
                      tl_pmp2d.d_ready = tl_h2pmp.d_ready;             
                      tl_pmp2h = tl_d2pmp;                              
                      tl_pmp2d.a_valid = 1'b0;  
                      irq_d = 1'b0;             
                      if (tl_h2pmp.a_valid && tl_d2pmp.a_ready) begin 
                        pmp_req_addr [0] = tl_h2pmp.a_address;
                        if (tl_h2pmp.a_opcode == 3'h0 || tl_h2pmp.a_opcode == 3'h1) begin
                          pmp_req_type [0] = PMP_ACC_WRITE;  			
                        end else if (tl_h2pmp.a_opcode == 3'h4) begin
                          pmp_req_type [0] = PMP_ACC_READ; 			
                        end
                        if (pmp_req_err[0]) begin                                            
                          next_state = block;
                          tl_pmp2d.a_valid = 1'b0;
                          denied_req_addr_d = tl_h2pmp.a_address;
                          denied_req_type_d = tl_h2pmp.a_opcode;
                          go_to_idle_d = 1'b0;
                          irq_d = 1'b1;
                          end
                        else begin 
                          tl_pmp2d = tl_h2pmp;
                        end                      
                      end                     
                    end                                              
                                                                   
      
      block :       begin
		      next_state = block;	 
                      tl_pmp2h.a_ready = 1'b0;						
                      tl_pmp2d.d_ready = 1'b0;	
                      err_rsp_sent_d = err_rsp_sent_q;				                    
                      if (tl_h2pmp.d_ready & !err_rsp_sent_q) begin			
                        tl_pmp2h = tl_err_rsp_device_outstanding;
			                  tl_pmp2h.a_ready = 1'b0;
                        err_rsp_sent_d = 1'b1;		
                      end else if (err_rsp_sent_q) begin        				              
                        tl_pmp2d.d_ready = tl_h2pmp.d_ready;
                        tl_pmp2h = tl_d2pmp;
                        if (go_to_idle_q & denied_addr_read_q & denied_req_type_read_q) begin
                          next_state = idle;
                          err_rsp_sent_d = 1'b0;
                          go_to_idle_d = 1'b0;  
		                      irq_d = 1'b0;   
                        end 
		      end  
                    end
                    
    endcase
  end
endmodule
  
  
  
 
