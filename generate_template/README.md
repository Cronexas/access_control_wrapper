# generate_template
This script is used to generate the basic UPEC files in SystemVerilog.

The following files will be generated:
 - A miter circuit in SystemVerilog
 - A property file template in SystemVerilogAssertions
 - A separate file containing the state_equivalence macro

Authors: JM, LD

## Instructions:
 1. Load, elaborate and compile your design in OneSpin
 2. Run the TCL script (output will be generated in the current working directory)
 3. Use the generated "miter_top.sv" as new top in OneSpin
 4. If required, adjust some stuff in the "miter_top.sv" (constant inputs etc.).
    This includes unsupported functionality as listed below.
 5. Switch to mv mode
 6. Load the "upec.sva" property template

## Note:
So far unsupported:
 - nested/multi dimensional arrays
 - parameters/generics
 - inouts
 - something other than symbolic memory representations
