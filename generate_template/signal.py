#!/usr/bin/env python3

class Signal:
    def __init__(self, direction, state, clk, rst, signal_type, full_name):
        self.direction = direction
        self.state = state == 'true'
        self.clk = clk != 'none'
        self.rst = rst
        self.signal_type = signal_type
        self.full_name = full_name
        self.signal_name = full_name.split('.')[-1]
        self.top_name = '.'.join(full_name.split('.')[:-1])
        self.miter_name = '.'.join(full_name.split('.')[1:])
