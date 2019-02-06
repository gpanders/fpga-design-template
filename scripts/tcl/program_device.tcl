open_hw
connect_hw_server
open_hw_target
set device [get_hw_devices -of_objects [current_hw_target]]
current_hw_device $device
refresh_hw_device -update_hw_probes false [lindex $device 0]

set probes_file [glob bitstream/*.ltx]
set bitstream [glob bitstream/*.bit]

if { ![llength $bitstream] } {
  puts "ERROR: Bitstream file not found."
  return 1
} elseif { [llength $bitstream] > 1 } {
  puts "ERROR: More than one bitstream file found!"
  return 1
}

if { [llength $probes_file] > 1 } {
  puts "ERROR: More than one probes file found!"
  return 1
}

set bitstream [file normalize $bitstream]
set probes_file [file normalize $probes_file]

set_property PROBES.FILE $probes_file $device
set_property FULL_PROBES.FILE $probes_file $device
set_property PROGRAM.FILE $bitstream $device

program_hw_devices $device
refresh_hw_device [lindex $device 0]

quit
