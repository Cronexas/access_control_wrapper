
import ibex_pkg::*;
import tlul_pkg::*;

module wrapper_fsm_tb3;

  logic clk_tb = 1;
  logic rst_tb = 0;
  
  tlul_pkg::tl_h2d_t  	    tl_h2pmp_tb = '0;
  tlul_pkg::tl_h2d_t	      tl_pmp2d_tb;
  tlul_pkg::tl_d2h_t	      tl_d2pmp_tb = '0;
  tlul_pkg::tl_d2h_t        tl_pmp2h_tb;
  tlul_pkg::tl_h2d_t        tl_cpu2csr_tb = '0;
  tlul_pkg::tl_d2h_t        tl_csr2cpu_tb;
   
  logic                     irq_tb;
  
  logic [5:0]               step = '0;              
  
  logic [5:0]               step_testing = '0;      
  
  logic [5:0]               step_isr = '0;
  
  logic                     setup_finished = 1'b0;
  
  wrapper_ibex_pmp_fsm2 dut (
    .rst(rst_tb),
    .clk(clk_tb),
    .irq_q(irq_tb),
    .tl_h2pmp(tl_h2pmp_tb),
    .tl_pmp2h(tl_pmp2h_tb),
    .tl_d2pmp(tl_d2pmp_tb),
    .tl_pmp2d(tl_pmp2d_tb),
    .tl_cpu2csr(tl_cpu2csr_tb),
    .tl_csr2cpu(tl_csr2cpu_tb)
    );
    
  always
    begin
      #5 clk_tb = 0;
      #5 clk_tb = 1;
    end  
    
  always_comb
    begin
      tl_cpu2csr_tb.d_ready <= !tl_cpu2csr_tb.a_valid;
      tl_h2pmp_tb.d_ready <= !tl_h2pmp_tb.a_valid;   
    end
 
  always_ff @(posedge clk_tb) begin    
    
    if (step == 0) begin
      rst_tb <= 1;
      step <= 1;
    end  
    
    if (step == 1) begin                              //send first message, hold valid high until wrapper ready then go to step 2
      tl_cpu2csr_tb.a_opcode <= PutFullData;
      tl_cpu2csr_tb.a_address <= 32'hffff_ff00;       //addr base 
      tl_cpu2csr_tb.a_data <= 32'b00101011_00101010_00101001_00101000;
      tl_cpu2csr_tb.a_source <= 8'h00;
      tl_cpu2csr_tb.a_valid <= 1'b1;
      if (tl_csr2cpu_tb.a_ready) begin                //wait until wrapper ready
        step <= 2;
      end
    end
      
    if (step == 2) begin                              //set valid low and ready high
      tl_cpu2csr_tb.a_valid <= 1'b0;  
      step <= 3;
    end   
    
    if (step == 3) begin                              //wait for ack, after ack sent another message (valid high)
      if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h00 && tl_csr2cpu_tb.d_opcode == AccessAck) begin
        tl_cpu2csr_tb.a_opcode <= PutFullData;
        tl_cpu2csr_tb.a_address <= 32'hffff_ff04;     //addr base +4
        //tl_cpu2csr_tb.a_data <= 32'h0000_0010;
        tl_cpu2csr_tb.a_data <= 32'h0000_0040;
        tl_cpu2csr_tb.a_source <= 8'h01;
        tl_cpu2csr_tb.a_valid <= 1'b1;
      end
      if (tl_csr2cpu_tb.a_ready) begin                //if wrapper ready set valid low 
        step <= 4;
        tl_cpu2csr_tb.a_valid <= 1'b0;  
      end
    end
    
    if (step == 4) begin
      if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h01 && tl_csr2cpu_tb.d_opcode == AccessAck) begin
        tl_cpu2csr_tb.a_opcode <= PutFullData;
        tl_cpu2csr_tb.a_address <= 32'hffff_ff08;     //addr base+8
        //tl_cpu2csr_tb.a_data <= 32'h0000_1000;
        tl_cpu2csr_tb.a_data <= 32'h0000_0080;
        tl_cpu2csr_tb.a_source <= 8'h02;
        tl_cpu2csr_tb.a_valid <= 1'b1;
      end
      if (tl_csr2cpu_tb.a_ready) begin
        step <= 6;
        tl_cpu2csr_tb.a_valid <= 1'b0;
      end
    end
    
    if (step == 6) begin
      if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h02 && tl_csr2cpu_tb.d_opcode == AccessAck) begin
        tl_cpu2csr_tb.a_opcode <= PutFullData;
        tl_cpu2csr_tb.a_address <= 32'hffff_ff0c;     //addr base+12
        //tl_cpu2csr_tb.a_data <= 32'h0010_0000;
        tl_cpu2csr_tb.a_data <= 32'h0000_00C0;
        tl_cpu2csr_tb.a_source <= 8'h03;
        tl_cpu2csr_tb.a_valid <= 1'b1;
      end
      if (tl_csr2cpu_tb.a_ready) begin
        step <= 7;
        tl_cpu2csr_tb.a_valid <= 1'b0; 
      end
    end
    
    if (step == 7) begin
      if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h03 && tl_csr2cpu_tb.d_opcode == AccessAck) begin
        tl_cpu2csr_tb.a_opcode <= PutFullData;
        tl_cpu2csr_tb.a_address <= 32'hffff_ff10;     //addr base+16
        //tl_cpu2csr_tb.a_data <= 32'h1000_0000;
        tl_cpu2csr_tb.a_data <= 32'h0000_0100;
        tl_cpu2csr_tb.a_source <= 8'h04;
        tl_cpu2csr_tb.a_valid <= 1'b1;
      end
      if (tl_csr2cpu_tb.a_ready) begin
        step <= 8;
        tl_cpu2csr_tb.a_valid <= 1'b0; 
      end
    end
    
    if (step == 8) begin
      if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h04 && tl_csr2cpu_tb.d_opcode == AccessAck) begin
        tl_cpu2csr_tb.a_opcode <= Get;
        tl_cpu2csr_tb.a_address <= 32'hffff_ff19;     //addr base+25
        tl_cpu2csr_tb.a_source <= 8'h05;
        tl_cpu2csr_tb.a_valid <= 1'b1;
      end
      if (tl_csr2cpu_tb.a_ready) begin
        step <= 9;
        tl_cpu2csr_tb.a_valid <= 1'b0;
      end
    end
    
    if (step == 9) begin
      if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h05 && tl_csr2cpu_tb.d_opcode == AccessAckData) begin
        tl_cpu2csr_tb.a_opcode <= Get;
        tl_cpu2csr_tb.a_address <= 32'hffff_ff0c;     //addr base+12
        tl_cpu2csr_tb.a_source <= 8'h06;
        tl_cpu2csr_tb.a_valid <= 1'b1;
      end
      if (tl_csr2cpu_tb.a_ready) begin
        step <= 10;
        tl_cpu2csr_tb.a_valid <= 1'b0;
      end
    end
    
    if (step == 10) begin
      if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h06 && tl_csr2cpu_tb.d_opcode == AccessAckData) begin
        step <= 11;
      end
    end
    
    if (step == 11) begin
   //  $finish;
      step <= 12;
    end
    
  end 
  
  always_ff @(posedge clk_tb) begin                   //master sends message
  
    tl_h2pmp_tb.d_ready <= !tl_h2pmp_tb.a_valid;        
    tl_d2pmp_tb.a_ready <= 1'b1;                      //device always ready
  
    if (step == 12) begin                             //if setup is done
    
      if (step_testing == 0) begin                    // this read message is allowed
        //tl_h2pmp_tb.a_address <= 32'h0000_0100;
        //tl_h2pmp_tb.a_address <= 32'h0000_0028;   
        tl_h2pmp_tb.a_address <= 32'h0000_005F;  
        tl_h2pmp_tb.a_data <= '0;
        tl_h2pmp_tb.a_opcode <= Get;
        tl_h2pmp_tb.a_source <= 8'h00;
        tl_h2pmp_tb.a_valid <= 1'b1;
        if (tl_pmp2h_tb.a_ready) begin
          step_testing <= 1;
        end
      end
      
      if (step_testing == 1) begin                    //set valid low after 1cc if wrapper was ready (-> message accepted)
        tl_h2pmp_tb.a_valid <= 1'b0;
        step_testing <= 2;
      end
      
      if (step_testing == 2) begin                    // this write message is allowed
        //tl_h2pmp_tb.a_address <= 32'h0001_0000;
        //tl_h2pmp_tb.a_address <= 32'h0000_0068;
        tl_h2pmp_tb.a_address <= 32'h0000_009B;
        tl_h2pmp_tb.a_data <= 32'hdead_beef;
        tl_h2pmp_tb.a_opcode <= PutFullData;
        tl_h2pmp_tb.a_source <= 8'h01;
        tl_h2pmp_tb.a_valid <= 1'b1;
        if (tl_pmp2h_tb.a_ready) begin
          step_testing <= 3;
        end
      end
      
      if (step_testing == 3) begin                    //set valid low after 1cc if wrapper was ready (-> message accepted)
        tl_h2pmp_tb.a_valid <= 1'b0;
        step_testing <= 4;
      end
      
      if (step_testing == 4) begin                   //this read message will get denied
        //tl_h2pmp_tb.a_address <= 32'h0001_0000;
        tl_h2pmp_tb.a_address <= 32'h0000_0028;
        tl_h2pmp_tb.a_data <= '0;
        tl_h2pmp_tb.a_opcode <= Get;
        tl_h2pmp_tb.a_source <= 8'h02;
        tl_h2pmp_tb.a_valid <= 1'b1;
        if (tl_pmp2h_tb.a_ready) begin
          step_testing <= 5;
        end
      end
      
      if (step_testing == 5) begin                   //set valid low after 1cc if wrapper was ready (-> message accepted)
        tl_h2pmp_tb.a_valid <= 1'b0;
        step_testing <= 6;
      end
      
      if (step_testing == 6) begin
//        $finish;
      end
      
      if (step_isr == 5) begin
//        $finish;
        step_isr <= 6;
      end
      
      if (step_isr == 6) begin
        $finish;
      end
      
    end
  end
  
  always_ff @(posedge clk_tb) begin
  
    if(irq_tb) begin

      if (step_isr == 0) begin    
        tl_cpu2csr_tb.a_opcode <= Get;        
        tl_cpu2csr_tb.a_address <= 32'hffff_ff14;   //addr base+20 (read denied request addr)
        tl_cpu2csr_tb.a_source <= 8'h10;
        tl_cpu2csr_tb.a_valid <= 1'b1;
        if (tl_csr2cpu_tb.a_ready) begin            //wait until wrapper ready
          step_isr <= 1;
        end
      end
      
      if (step_isr == 1) begin
        step_isr <= 2;
        tl_cpu2csr_tb.a_valid <= 1'b0;
      end
      
      if (step_isr == 2) begin
        if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h10 && tl_csr2cpu_tb.d_opcode == AccessAckData) begin
          tl_cpu2csr_tb.a_opcode <= Get;
          tl_cpu2csr_tb.a_address <= 32'hffff_ff18;   //addr base +24 (read denied request type)
          tl_cpu2csr_tb.a_source <= 8'h11;
          tl_cpu2csr_tb.a_valid <= 1'b1;
        end
        if (tl_csr2cpu_tb.a_ready) begin              //if wrapper ready set valid low 
          step_isr <= 3;
          tl_cpu2csr_tb.a_valid <= 1'b0;  
        end  
      end
      
      if (step_isr == 3) begin
        if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h11 && tl_csr2cpu_tb.d_opcode == AccessAckData) begin
          tl_cpu2csr_tb.a_opcode <= PutPartialData;
          tl_cpu2csr_tb.a_address <= 32'hffff_ff1A;   //addr base +26 (set go_to_idle bit)
          tl_cpu2csr_tb.a_data <= 32'h0000_0001;      //doesnt need to write anything to set bit only select address
          tl_cpu2csr_tb.a_source <= 8'h12;
          tl_cpu2csr_tb.a_valid <= 1'b1;
        end
        if (tl_csr2cpu_tb.a_ready) begin              //if wrapper ready set valid low 
          step_isr <= 4;
          tl_cpu2csr_tb.a_valid <= 1'b0;  
        end  
      end
      
      if (step_isr == 4) begin
        if (tl_csr2cpu_tb.d_valid && tl_csr2cpu_tb.d_source == 8'h12 && tl_csr2cpu_tb.d_opcode == AccessAck) begin
          step_isr <= 5;
        end
      end
      
      if (step_isr == 5) begin
//        step_isr <= 0;
        $finish;
      end
       
           
    end
  end
  
endmodule
