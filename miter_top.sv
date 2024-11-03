module miter_top (
  input clk,
  input rst,
  output logic irq_q_1,
  output logic irq_q_2,
  input tlul_pkg::tl_h2d_t tl_cpu2csr_1,
  input tlul_pkg::tl_h2d_t tl_cpu2csr_2,
  output tlul_pkg::tl_d2h_t tl_csr2cpu_1,
  output tlul_pkg::tl_d2h_t tl_csr2cpu_2,
  input tlul_pkg::tl_d2h_t tl_d2pmp_1,
  input tlul_pkg::tl_d2h_t tl_d2pmp_2,
  input tlul_pkg::tl_h2d_t tl_h2pmp_1,
  input tlul_pkg::tl_h2d_t tl_h2pmp_2,
  output tlul_pkg::tl_h2d_t tl_pmp2d_1,
  output tlul_pkg::tl_h2d_t tl_pmp2d_2,
  output tlul_pkg::tl_d2h_t tl_pmp2h_1,
  output tlul_pkg::tl_d2h_t tl_pmp2h_2
);

logic rst_n;
logic [3:0] Register_d;
logic [3:0] Register_q;
assign rst_n = !rst;

access_control_wrapper U1(
  .clk(clk),
  .irq_q(irq_q_1),
  .rst(rst_n),
  .tl_cpu2csr(tl_cpu2csr_1),
  .tl_csr2cpu(tl_csr2cpu_1),
  .tl_d2pmp(tl_d2pmp_1),
  .tl_h2pmp(tl_h2pmp_1),
  .tl_pmp2d(tl_pmp2d_1),
  .tl_pmp2h(tl_pmp2h_1)
);

access_control_wrapper U2(
  .clk(clk),
  .irq_q(irq_q_2),
  .rst(rst_n),
  .tl_cpu2csr(tl_cpu2csr_2),
  .tl_csr2cpu(tl_csr2cpu_2),
  .tl_d2pmp(tl_d2pmp_2),
  .tl_h2pmp(tl_h2pmp_2),
  .tl_pmp2d(tl_pmp2d_2),
  .tl_pmp2h(tl_pmp2h_2)
);
/*
always_ff @(posedge clk, negedge rst_n) 
begin     
    if (!rst_n) begin                    
	Register_q <= 1'b0;
    end else begin
	Register_q <= Register_d;
    end
end

assign Register_d = Register_q;
*/
endmodule // miter_top
