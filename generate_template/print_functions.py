def print_inst(inst_nr, if_signals):
    inst_str = if_signals[0].top_name + ' U' + str(inst_nr) + '(\n'
    for s in if_signals:
        if s.clk:
            inst_str += '  .' + s.signal_name + '(clk)'
        elif s.rst != 'none':
            if s.rst == 'neg_reset':
                inst_str += '  .' + s.signal_name + '(rst_n)'
            else:
                inst_str += '  .' + s.signal_name + '(rst)'
        else:
            inst_str += f'  .{s.signal_name}({s.signal_name}_{inst_nr})'
        inst_str += ',\n' if s != if_signals[-1] else '\n'
    inst_str += ');\n\n'

    return inst_str


def print_miter(if_signals):
    miter_str = 'module miter_top (\n  input clk,\n  input rst,\n'
    for s in if_signals:
        if not s.clk and s.rst == 'none':
            miter_str += '  ' + s.direction + ' ' + s.signal_type + ' ' + s.signal_name + '_1,\n'
            miter_str += '  ' + s.direction + ' ' + s.signal_type + ' ' + s.signal_name + '_2'
            miter_str += ',\n' if s != if_signals[-1] else '\n'
    miter_str += ');\n\n'

    # creating active low reset alternative
    miter_str += 'logic rst_n;\nassign rst_n = !rst;\n\n'

    miter_str += print_inst(1, if_signals)
    miter_str += print_inst(2, if_signals)
    miter_str += 'endmodule // miter_top\n'

    return miter_str


def print_state_equivalence(state_signals):
    se_str = 'function automatic state_equivalence();\nstate_equivalence = (\n'
    for s in state_signals:
        se_str += "  (U1." + s.miter_name + " == U2." + s.miter_name
        se_str += ")\n" if s == state_signals[-1] else ") &&\n"
    se_str += ");\nendfunction\n"

    return se_str


def print_property_checker(rst_signal):
    active = '0' if rst_signal.rst == 'neg_reset' else '1'
    pc_str = 'module property_checker\n  (\n'
    pc_str += '  input clk,\n'
    pc_str += '  input rst\n  );\n\n'
    pc_str += 'default clocking default_clk @(posedge clk); endclocking\n\n'
    pc_str += '`include "tidal.sv"\n\n'
    pc_str += '`include "state_equivalence.sva"\n\n'
    pc_str += '`begin_tda(ops)\n\n'
    pc_str += '  sequence reset_sequence;\n'
    pc_str += '    (rst == 1\'b' + active + ');\n'
    pc_str += '  endsequence\n\n'
    pc_str += '`end_tda\n\n'
    pc_str += 'endmodule\n\n'
    pc_str += 'bind miter_top property_checker checker_bind(.clk(clk), .rst(rst));'
    return pc_str
