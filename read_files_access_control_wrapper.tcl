# I used this script to load all files necessary to run some UPEC verification on the OpenTitan OTP controller.
# You can change it for your project as you see fit.

restart -force

# It is good to limit the amount of RAM that you allow OneSpin to use (to avoid unnecessary computer strokes).
set_limit -global_memory 30720

# This changes the base directory, as mentioned in the email. All file paths are defined relative to the base directory
## Changing working directory to path where access control wrapper is stored.
cd /import/lab/users/dschwarz/Documents/Control_Wrapper_TU_UL/access_controL_wrapper/

# This is the latest supported SystemVerilog version in OneSpin, so it's the one with the most features
set_read_hdl_option -golden -verilog_version sv2012

# If your design has some global parameters that need defining, you can do that as follows:
## I dont know all of the options, so i leave the in comment for now.
set_read_hdl_option -verilog_define {VERILATOR=0 SYNTHESIS=0 YOSIS=0 UVM=0 FPV_ON=1 SIMULATION=0}

# To avoid import and include files not being recognized, here you can specify the file paths where those files are located
## Relative Paths
set_read_hdl_option -verilog_include_path {packages}
##set_read_hdl_option -verilog_library_path {ip/prim/rtl ip/tlul/rtl ip/otp_ctrl/rtl ip/prim_generic/rtl vendor/lowrisc_ibex/dv/uvm/core_ibex/common/prim/ ip/lc_ctrl/rtl}
## set_read_hdl_option -verilog_include_path {ip/prim/rtl}
  
# Read in all the individual files
read_verilog -golden  -pragma_ignore {} packages/dv_fcov_macros.svh
read_verilog -golden  -pragma_ignore {} packages/ibex_csr.sv
read_verilog -golden  -pragma_ignore {} packages/ibex_pkg.sv
read_verilog -golden  -pragma_ignore {} packages/ibex_pmp.sv
read_verilog -golden  -pragma_ignore {} packages/prim_assert.sv
read_verilog -golden  -pragma_ignore {} packages/prim_assert_sec_cm.svh
read_verilog -golden  -pragma_ignore {} packages/prim_assert_standard_macros.svh
read_verilog -golden  -pragma_ignore {} packages/prim_flop_macros.sv
read_verilog -golden  -pragma_ignore {} packages/prim_mubi_pkg.sv
read_verilog -golden  -pragma_ignore {} packages/prim_secded_39_32_enc.sv
read_verilog -golden  -pragma_ignore {} packages/prim_secded_inv_39_32_enc.sv
read_verilog -golden  -pragma_ignore {} packages/prim_secded_inv_64_57_enc.sv
read_verilog -golden  -pragma_ignore {} packages/prim_secded_pkg.sv
read_verilog -golden  -pragma_ignore {} packages/tlul_data_integ_enc.sv
read_verilog -golden  -pragma_ignore {} packages/tlul_err_resp.sv
read_verilog -golden  -pragma_ignore {} packages/tlul_pkg.sv
read_verilog -golden  -pragma_ignore {} packages/tlul_rsp_intg_gen.sv
read_verilog -golden  -pragma_ignore {} packages/top_pkg.sv
read_verilog -golden  -pragma_ignore {} packages/access_control_wrapper_reg_pkg.sv
read_verilog -golden  -pragma_ignore {} packages/access_control_wrapper_reg_top.sv
read_verilog -golden  -pragma_ignore {} packages/prim_intr_hw.sv
read_verilog -golden  -pragma_ignore {} packages/prim_assert_dummy_macros.svh
read_verilog -golden  -pragma_ignore {} packages/prim_reg_we_check.sv
read_verilog -golden  -pragma_ignore {} packages/prim_buf.sv
read_verilog -golden  -pragma_ignore {} packages/prim_util_pkg.sv
read_verilog -golden  -pragma_ignore {} packages/prim_onehot_check.sv
read_verilog -golden  -pragma_ignore {} packages/tlul_cmd_intg_chk.sv
read_verilog -golden  -pragma_ignore {} packages/prim_secded_inv_64_57_dec.sv
read_verilog -golden  -pragma_ignore {} packages/tlul_data_integ_dec.sv
read_verilog -golden  -pragma_ignore {} packages/prim_secded_inv_39_32_dec.sv
read_verilog -golden  -pragma_ignore {} packages/tlul_adapter_reg.sv
read_verilog -golden  -pragma_ignore {} packages/tlul_err.sv
read_verilog -golden  -pragma_ignore {} packages/prim_subreg_pkg.sv
read_verilog -golden  -pragma_ignore {} packages/prim_subreg.sv
read_verilog -golden  -pragma_ignore {} packages/prim_subreg_arb.sv
read_verilog -golden  -pragma_ignore {} packages/prim_subreg_ext.sv
read_verilog -golden  -pragma_ignore {} access_control_wrapper.sv
#read_verilog -golden  -pragma_ignore {} packages/
#read_verilog -golden  -pragma_ignore {} packages/
#read_verilog -golden  -pragma_ignore {} packages/






#read_verilog -golden  -pragma_ignore {} ip/tlul/rtl/tlul_pkg.sv
#read_verilog -golden  -pragma_ignore {} ip/ibex/rtl/ibex_pkg.sv




# Sometimes OneSpin can't figure out what file should be the top file. You can manually specify it like this:
#set_elaborate_option -top !work.miter_top
#read_verilog -golden  -pragma_ignore {} access_control_wrapper.sv
read_verilog -golden  -pragma_ignore {} miter_top.sv
#set_elaborate_option -top verilog!work.access_control_wrapper
set_elaborate_option -top verilog!work.miter_top
# Elaborate the design
elaborate -golden

# If your design becomes too complex, you can blackbox certain components out to simplify it
#set_compile_option -golden -black_box_instances {  {U1/u_otp/u_prim_ram_1p_adv/u_mem} {U2/u_otp/u_prim_ram_1p_adv/u_mem} }

# Compile the design
compile -golden

# You're now ready for verification. Switch mode to MV
set_mode mv

# Read your property file
# rename with file with tidal-assertions
#read_sva upec.sva
read_sva access_controll_wrapper_testbench.tda

# We'll leave the rest for later :)