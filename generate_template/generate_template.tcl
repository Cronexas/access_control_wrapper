# @lang=tcl @ts=8

set script_path [file dirname [file normalize [info script]]]

set input_list [get_signals_sv -golden -local -filter direction==input||direction==output]
set signal_list [get_signals_sv -golden -filter state==true]

start_message_log -force $script_path/onespin_signal_list.log

foreach s [concat $input_list $signal_list] {
	set direction [get_signal_info -direction $s]
	set state [get_signal_info -state $s]
	set clock [get_signal_info -clock $s]
	set reset [get_signal_info -reset $s]
	set type [get_signal_info -type $s]
	puts [concat $direction $state $clock $reset $type $s]
}

stop_message_log

exec python3 $script_path/generate_template.py