#!/usr/bin/env python3
# Author: JM, LD
import os
import re
from signal import Signal
from print_functions import *

# read OneSpin signal log and put all information nicely into Signal objects
script_path = os.path.dirname(os.path.abspath(__file__))
input_file_name = 'onespin_signal_list.log'
rf = open(script_path + '/' + input_file_name, 'r')
string_lines = rf.readlines()
rf.close()

state_signals, if_signals = [], []
rst_signal = ''
for line in string_lines:
    m = re.search(r'^(\S+) (\S+) (\S+) (\S+) (\S+) (\S+)', line)
    if not m:
        continue
    signal = Signal(m.group(1), m.group(2), m.group(3), m.group(4), m.group(5), m.group(6))
    if signal.state:
        state_signals.append(signal)
    if signal.direction != 'internal':
        if_signals.append(signal)
    if signal.rst != 'none':
        rst_signal = signal

wf = open('miter_top.sv', 'w')
wf.write(print_miter(if_signals))
wf.close()

wf = open('state_equivalence.sva', 'w')
wf.write(print_state_equivalence(state_signals))
wf.close()

wf = open('upec.sva', 'w')
wf.write(print_property_checker(rst_signal))
wf.close()

# delete temporary log file
if os.path.isfile(script_path + '/' + input_file_name):
    os.remove(script_path + '/' + input_file_name)
