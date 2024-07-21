// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package access_control_wrapper_reg_pkg;

  // Param list
  parameter int NumAlerts = 1;

  // Address widths within the block
  parameter int BlockAw = 6;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////

  typedef struct packed {
    logic [31:0] q;
  } access_control_wrapper_reg2hw_intr_state_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } access_control_wrapper_reg2hw_intr_enable_reg_t;

  typedef struct packed {
    logic [31:0] q;
    logic        qe;
  } access_control_wrapper_reg2hw_intr_test_reg_t;

  typedef struct packed {
    logic        q;
    logic        qe;
  } access_control_wrapper_reg2hw_alert_test_reg_t;

  typedef struct packed {
    logic [31:0] q;
    logic        qe;
  } access_control_wrapper_reg2hw_direct_out_reg_t;

  typedef struct packed {
    struct packed {
      logic [15:0] q;
      logic        qe;
    } mask;
    struct packed {
      logic [15:0] q;
      logic        qe;
    } data;
  } access_control_wrapper_reg2hw_masked_out_lower_reg_t;

  typedef struct packed {
    struct packed {
      logic [15:0] q;
      logic        qe;
    } mask;
    struct packed {
      logic [15:0] q;
      logic        qe;
    } data;
  } access_control_wrapper_reg2hw_masked_out_upper_reg_t;

  typedef struct packed {
    logic [31:0] q;
    logic        qe;
  } access_control_wrapper_reg2hw_direct_oe_reg_t;

  typedef struct packed {
    struct packed {
      logic [15:0] q;
      logic        qe;
    } mask;
    struct packed {
      logic [15:0] q;
      logic        qe;
    } data;
  } access_control_wrapper_reg2hw_masked_oe_lower_reg_t;

  typedef struct packed {
    struct packed {
      logic [15:0] q;
      logic        qe;
    } mask;
    struct packed {
      logic [15:0] q;
      logic        qe;
    } data;
  } access_control_wrapper_reg2hw_masked_oe_upper_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } access_control_wrapper_reg2hw_intr_ctrl_en_rising_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } access_control_wrapper_reg2hw_intr_ctrl_en_falling_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } access_control_wrapper_reg2hw_intr_ctrl_en_lvlhigh_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } access_control_wrapper_reg2hw_intr_ctrl_en_lvllow_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } access_control_wrapper_reg2hw_ctrl_en_input_filter_reg_t;

  typedef struct packed {
    logic [31:0] d;
    logic        de;
  } access_control_wrapper_hw2reg_intr_state_reg_t;

  typedef struct packed {
    logic [31:0] d;
    logic        de;
  } access_control_wrapper_hw2reg_data_in_reg_t;

  typedef struct packed {
    logic [31:0] d;
  } access_control_wrapper_hw2reg_direct_out_reg_t;

  typedef struct packed {
    struct packed {
      logic [15:0] d;
    } data;
    struct packed {
      logic [15:0] d;
    } mask;
  } access_control_wrapper_hw2reg_masked_out_lower_reg_t;

  typedef struct packed {
    struct packed {
      logic [15:0] d;
    } data;
    struct packed {
      logic [15:0] d;
    } mask;
  } access_control_wrapper_hw2reg_masked_out_upper_reg_t;

  typedef struct packed {
    logic [31:0] d;
  } access_control_wrapper_hw2reg_direct_oe_reg_t;

  typedef struct packed {
    struct packed {
      logic [15:0] d;
    } data;
    struct packed {
      logic [15:0] d;
    } mask;
  } access_control_wrapper_hw2reg_masked_oe_lower_reg_t;

  typedef struct packed {
    struct packed {
      logic [15:0] d;
    } data;
    struct packed {
      logic [15:0] d;
    } mask;
  } access_control_wrapper_hw2reg_masked_oe_upper_reg_t;

  // Register -> HW type
  typedef struct packed {
    access_control_wrapper_reg2hw_intr_state_reg_t intr_state; // [460:429]
    access_control_wrapper_reg2hw_intr_enable_reg_t intr_enable; // [428:397]
    access_control_wrapper_reg2hw_intr_test_reg_t intr_test; // [396:364]
    access_control_wrapper_reg2hw_alert_test_reg_t alert_test; // [363:362]
    access_control_wrapper_reg2hw_direct_out_reg_t direct_out; // [361:329]
    access_control_wrapper_reg2hw_masked_out_lower_reg_t masked_out_lower; // [328:295]
    access_control_wrapper_reg2hw_masked_out_upper_reg_t masked_out_upper; // [294:261]
    access_control_wrapper_reg2hw_direct_oe_reg_t direct_oe; // [260:228]
    access_control_wrapper_reg2hw_masked_oe_lower_reg_t masked_oe_lower; // [227:194]
    access_control_wrapper_reg2hw_masked_oe_upper_reg_t masked_oe_upper; // [193:160]
    access_control_wrapper_reg2hw_intr_ctrl_en_rising_reg_t intr_ctrl_en_rising; // [159:128]
    access_control_wrapper_reg2hw_intr_ctrl_en_falling_reg_t intr_ctrl_en_falling; // [127:96]
    access_control_wrapper_reg2hw_intr_ctrl_en_lvlhigh_reg_t intr_ctrl_en_lvlhigh; // [95:64]
    access_control_wrapper_reg2hw_intr_ctrl_en_lvllow_reg_t intr_ctrl_en_lvllow; // [63:32]
    access_control_wrapper_reg2hw_ctrl_en_input_filter_reg_t ctrl_en_input_filter; // [31:0]
  } access_control_wrapper_reg2hw_t;

  // HW -> register type
  typedef struct packed {
    access_control_wrapper_hw2reg_intr_state_reg_t intr_state; // [257:225]
    access_control_wrapper_hw2reg_data_in_reg_t data_in; // [224:192]
    access_control_wrapper_hw2reg_direct_out_reg_t direct_out; // [191:160]
    access_control_wrapper_hw2reg_masked_out_lower_reg_t masked_out_lower; // [159:128]
    access_control_wrapper_hw2reg_masked_out_upper_reg_t masked_out_upper; // [127:96]
    access_control_wrapper_hw2reg_direct_oe_reg_t direct_oe; // [95:64]
    access_control_wrapper_hw2reg_masked_oe_lower_reg_t masked_oe_lower; // [63:32]
    access_control_wrapper_hw2reg_masked_oe_upper_reg_t masked_oe_upper; // [31:0]
  } access_control_wrapper_hw2reg_t;

  // Register offsets
  parameter logic [BlockAw-1:0] access_control_wrapper_INTR_STATE_OFFSET = 6'h 0;
  parameter logic [BlockAw-1:0] access_control_wrapper_INTR_ENABLE_OFFSET = 6'h 4;
  parameter logic [BlockAw-1:0] access_control_wrapper_INTR_TEST_OFFSET = 6'h 8;
  parameter logic [BlockAw-1:0] access_control_wrapper_ALERT_TEST_OFFSET = 6'h c;
  parameter logic [BlockAw-1:0] access_control_wrapper_DATA_IN_OFFSET = 6'h 10;
  parameter logic [BlockAw-1:0] access_control_wrapper_DIRECT_OUT_OFFSET = 6'h 14;
  parameter logic [BlockAw-1:0] access_control_wrapper_MASKED_OUT_LOWER_OFFSET = 6'h 18;
  parameter logic [BlockAw-1:0] access_control_wrapper_MASKED_OUT_UPPER_OFFSET = 6'h 1c;
  parameter logic [BlockAw-1:0] access_control_wrapper_DIRECT_OE_OFFSET = 6'h 20;
  parameter logic [BlockAw-1:0] access_control_wrapper_MASKED_OE_LOWER_OFFSET = 6'h 24;
  parameter logic [BlockAw-1:0] access_control_wrapper_MASKED_OE_UPPER_OFFSET = 6'h 28;
  parameter logic [BlockAw-1:0] access_control_wrapper_INTR_CTRL_EN_RISING_OFFSET = 6'h 2c;
  parameter logic [BlockAw-1:0] access_control_wrapper_INTR_CTRL_EN_FALLING_OFFSET = 6'h 30;
  parameter logic [BlockAw-1:0] access_control_wrapper_INTR_CTRL_EN_LVLHIGH_OFFSET = 6'h 34;
  parameter logic [BlockAw-1:0] access_control_wrapper_INTR_CTRL_EN_LVLLOW_OFFSET = 6'h 38;
  parameter logic [BlockAw-1:0] access_control_wrapper_CTRL_EN_INPUT_FILTER_OFFSET = 6'h 3c;

  // Reset values for hwext registers and their fields
  parameter logic [31:0] access_control_wrapper_INTR_TEST_RESVAL = 32'h 0;
  parameter logic [31:0] access_control_wrapper_INTR_TEST_access_control_wrapper_RESVAL = 32'h 0;
  parameter logic [0:0] access_control_wrapper_ALERT_TEST_RESVAL = 1'h 0;
  parameter logic [0:0] access_control_wrapper_ALERT_TEST_FATAL_FAULT_RESVAL = 1'h 0;
  parameter logic [31:0] access_control_wrapper_DIRECT_OUT_RESVAL = 32'h 0;
  parameter logic [31:0] access_control_wrapper_MASKED_OUT_LOWER_RESVAL = 32'h 0;
  parameter logic [31:0] access_control_wrapper_MASKED_OUT_UPPER_RESVAL = 32'h 0;
  parameter logic [31:0] access_control_wrapper_DIRECT_OE_RESVAL = 32'h 0;
  parameter logic [31:0] access_control_wrapper_MASKED_OE_LOWER_RESVAL = 32'h 0;
  parameter logic [31:0] access_control_wrapper_MASKED_OE_UPPER_RESVAL = 32'h 0;

  // Register index
  typedef enum int {
    access_control_wrapper_INTR_STATE,
    access_control_wrapper_INTR_ENABLE,
    access_control_wrapper_INTR_TEST,
    access_control_wrapper_ALERT_TEST,
    access_control_wrapper_DATA_IN,
    access_control_wrapper_DIRECT_OUT,
    access_control_wrapper_MASKED_OUT_LOWER,
    access_control_wrapper_MASKED_OUT_UPPER,
    access_control_wrapper_DIRECT_OE,
    access_control_wrapper_MASKED_OE_LOWER,
    access_control_wrapper_MASKED_OE_UPPER,
    access_control_wrapper_INTR_CTRL_EN_RISING,
    access_control_wrapper_INTR_CTRL_EN_FALLING,
    access_control_wrapper_INTR_CTRL_EN_LVLHIGH,
    access_control_wrapper_INTR_CTRL_EN_LVLLOW,
    access_control_wrapper_CTRL_EN_INPUT_FILTER
  } access_control_wrapper_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] access_control_wrapper_PERMIT [16] = '{
    4'b 1111, // index[ 0] access_control_wrapper_INTR_STATE
    4'b 1111, // index[ 1] access_control_wrapper_INTR_ENABLE
    4'b 1111, // index[ 2] access_control_wrapper_INTR_TEST
    4'b 0001, // index[ 3] access_control_wrapper_ALERT_TEST
    4'b 1111, // index[ 4] access_control_wrapper_DATA_IN
    4'b 1111, // index[ 5] access_control_wrapper_DIRECT_OUT
    4'b 1111, // index[ 6] access_control_wrapper_MASKED_OUT_LOWER
    4'b 1111, // index[ 7] access_control_wrapper_MASKED_OUT_UPPER
    4'b 1111, // index[ 8] access_control_wrapper_DIRECT_OE
    4'b 1111, // index[ 9] access_control_wrapper_MASKED_OE_LOWER
    4'b 1111, // index[10] access_control_wrapper_MASKED_OE_UPPER
    4'b 1111, // index[11] access_control_wrapper_INTR_CTRL_EN_RISING
    4'b 1111, // index[12] access_control_wrapper_INTR_CTRL_EN_FALLING
    4'b 1111, // index[13] access_control_wrapper_INTR_CTRL_EN_LVLHIGH
    4'b 1111, // index[14] access_control_wrapper_INTR_CTRL_EN_LVLLOW
    4'b 1111  // index[15] access_control_wrapper_CTRL_EN_INPUT_FILTER
  };

endpackage