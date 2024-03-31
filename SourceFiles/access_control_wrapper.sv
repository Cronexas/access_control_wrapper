//`timescale 1ns / 1ns

import tlul_pkg::*;
import ibex_pkg::*;

module wrapper_ibex_pmp_fsm2(

  input logic                       rst,
  input logic                       clk,
  output logic                      irq_q,
 
  input  tlul_pkg::tl_h2d_t  	    tl_h2pmp,               		//TLUL message untrusted master to wrapper (pmp)
  output tlul_pkg::tl_d2h_t         tl_pmp2h = '0,               	//error response message to untrusted master if permission denied
          
  input  tlul_pkg::tl_d2h_t	    tl_d2pmp,                 		//incoming message from device to pmp, gets relayed without change
  output tlul_pkg::tl_h2d_t	    tl_pmp2d = '0,               	//send message to device, if permission granted by pmp
  
  input  tlul_pkg::tl_h2d_t         tl_cpu2csr,              		//cpu writes the cfg and address register, seperate interface for security
  output tlul_pkg::tl_d2h_t         tl_csr2cpu = '0             	//wrapper send denied address and opcode to cpu  
  );
  
  //PMP parameters
  parameter int unsigned            PMPGranularity = 0;    
  parameter int unsigned            PMPNumChan = 1;
  parameter int unsigned            PMPNumRegions = 4;     		//n+(n/4) registers for n regions
  
  tlul_pkg::tl_d2h_t                tl_err_rsp_outstanding;   		
  
  ibex_pkg::pmp_mseccfg_t           csr_pmp_mseccfg = 1'b0;
  ibex_pkg::priv_lvl_e              priv_mode [PMPNumChan] = {2'b00}; 	//user mode
  
  //PMP i/o signals
  logic [33:0]             	    pmp_req_addr [PMPNumChan];     
  ibex_pkg::pmp_req_e      	    pmp_req_type [PMPNumChan];
  logic                    	    pmp_req_err  [PMPNumChan];
  
  //PMP cfg signals
  ibex_pkg::pmp_cfg_t      	    csr_pmp_cfg   [PMPNumRegions];
  logic [33:0]            	    csr_pmp_addr  [PMPNumRegions];
  
  //Register signals
  logic [31:0]                      wr_data_csr[4:0];         		//csr signals
  logic                             wr_en_csr[4:0] = {0, 0, 0, 0, 0};
  logic [31:0]                      rd_data_csr[4:0];      
  logic                             rd_error_csr[4:0];
  
  logic [4:0]                       cpu_addr_sel;
  
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
    
  tlul_err_resp err_resp_wrapper (
    .clk_i(clk),
    .rst_ni(rst),
    .tl_h_i(tl_h2pmp),
    .tl_h_o(tl_err_rsp_outstanding)
  );
  
  ////////////////////////////////  --assignements
  
  assign csr_pmp_cfg[0] = rd_data_csr[0];
  assign csr_pmp_cfg[1] = rd_data_csr[0] >> 8;
  assign csr_pmp_cfg[2] = rd_data_csr[0] >> 16;
  assign csr_pmp_cfg[3] = rd_data_csr[0] >> 24;
  assign csr_pmp_addr[0] = rd_data_csr[1];
  assign csr_pmp_addr[1] = rd_data_csr[2];
  assign csr_pmp_addr[2] = rd_data_csr[3];
  assign csr_pmp_addr[3] = rd_data_csr[4];
  
  ////////////////////////////////  -- CPU Interface

  always_comb begin 
  
    tl_csr2cpu.a_ready = !ack_outstanding_q;
  
    if (tl_cpu2csr.a_valid && tl_csr2cpu.a_ready) begin                    
      ack_outstanding_d = 1'b1;   
      source_id_d = tl_cpu2csr.a_source;
      cpu_addr_sel = tl_cpu2csr.a_address & 5'b11111;
      if (tl_cpu2csr.a_opcode == PutFullData || tl_cpu2csr.a_opcode == PutPartialData) begin                                                                  
        ack_opcode_d = AccessAck;
    
        case (cpu_addr_sel)
        
        5'b00000 :      begin                       			//addr 0, 4 cfg registers
                          wr_data_csr[0] = tl_cpu2csr.a_data;
                          wr_en_csr[0] = 1'b1;
                        end
        5'b00100 :      begin                       			//addr 4, pmp addr 0
                          wr_data_csr[1] = tl_cpu2csr.a_data;
                          wr_en_csr[1] = 1'b1;
                        end
        5'b01000 :      begin                       			//addr 8, pmp addr 1
                          wr_data_csr[2] = tl_cpu2csr.a_data;
                          wr_en_csr[2] = 1'b1;
                        end
        5'b01100 :      begin                       			//addr 12, pmp addr 2
                          wr_data_csr[3] = tl_cpu2csr.a_data;
                          wr_en_csr[3] = 1'b1;			  
                        end
        5'b10000 :      begin                       			//addr 16, pmp addr 3
                          wr_data_csr[4] = tl_cpu2csr.a_data;
                          wr_en_csr[4] = 1'b1;
                        end
        5'b11010 :      begin                       			//addr 26, cpu control during block
                          go_to_idle_d = 1;
                        end
        endcase
  
      end else if (tl_cpu2csr.a_opcode == Get) begin                                        
        ack_opcode_d = AccessAckData;
        
        case (cpu_addr_sel)
        
        5'b00000 :      begin                       			//addr 0, 4 cfg registers
                          tl_csr2cpu.d_data = rd_data_csr[0];
                        end
        5'b00100 :      begin                       			//addr 4, pmp addr 0
                          tl_csr2cpu.d_data = rd_data_csr[1];
                        end
        5'b01000 :      begin                       			//addr 8, pmp addr 1
                          tl_csr2cpu.d_data = rd_data_csr[2];
                        end
        5'b01100 :      begin                       			//addr 12, pmp addr 2
                          tl_csr2cpu.d_data = rd_data_csr[3];
                        end
        5'b10000 :      begin                       			//addr 16, pmp addr 3
                          tl_csr2cpu.d_data = rd_data_csr[4];
                        end
        5'b10100 :      begin                       			//addr 20, denied addr
                          tl_csr2cpu.d_data = denied_req_addr_q;
                        end
        5'b11000 :      begin                       			//addr 24, denied request type
                          tl_csr2cpu.d_data = denied_req_type_q;
                        end                
        5'b11001 :      begin                       			//addr 25, fsm state
                          tl_csr2cpu.d_data = current_state;
                        end
        endcase
  
      end
    end 
    
    if (ack_outstanding_q) begin              
                                            
      for (int i = 0; i <= 4; i++) begin                		//set write enables to 0 after every op
        wr_en_csr[i] = 1'b0;
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
                        tl_pmp2h = tl_err_rsp_outstanding;
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
  
  
  
 
