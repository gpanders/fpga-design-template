# Set working directory to this script's parent directory
set root_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
cd $root_dir

# Set default options
if { ![info exists create_reports] } { set create_reports 1 }
if { ![info exists debug] } { set debug 1 }
if { ![info exists write_dcp] } { set write_dcp 1 }
if { ![info exists start_from] } { set start_from "" }
if { ![info exists run_to] } { set run_to $start_from }
if { ![info exists incr_checkpoint] } { set incr_checkpoint "" }

# Read command line arguments, if present
if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--name"              { incr i; set name [lindex $::argv $i] }
      "--top"               { incr i; set top [lindex $::argv $i] }
      "--part"              { incr i; set part [lindex $::argv $i] }
      "--synth_constraints" { incr i; set synth_constraints [split [lindex $::argv $i] ","] }
      "--impl_constraints"  { incr i; set impl_constraints [split [lindex $::argv $i] ","] }
      "--debug_constraints" { incr i; set debug_constraints [split [lindex $::argv $i] ","] }
      "--ip_repo_paths"     { incr i; set ip_repo_paths [split [lindex $::argv $i] ","] }
      "--no_report"         { set create_reports 0 }
      "--no_debug"          { set debug 0 }
      "--fast"              { set create_reports 0; set debug 0; set write_dcp 0 }
      "--run_to"            { incr i; set run_to [string tolower [lindex $::argv $i]] }
      "--start_from"        { incr i; set start_from [string tolower [lindex $::argv $i]] }
      "--incremental"       { incr i; set incr_checkpoint [lindex $::argv $i] }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified.\n"
          return 1
        }
      }
    }
  }
}

# Convert string to int for easier comparison
switch $start_from {
  0 - ""      { set start_from 0 }
  1 - "synth" { set start_from 1 }
  2 - "opt"   { set start_from 2 }
  3 - "place" { set start_from 3 }
  4 - "route" { set start_from 4 }
  default {
    puts "ERROR: Unknown value for option 'start_from': ${start_from}.\n"
    return 1
  }
}

set now [clock format [clock seconds] -format %H:%M:%S]
puts "Build started at $now"

# Create output directory
set output_dir build
file mkdir $output_dir

# Set part
set_part $part

# Enable XPMs
set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]

if { $start_from == 0 } {
  # Include custom IP repositories
  set_property ip_repo_paths $ip_repo_paths [current_fileset]
  update_ip_catalog

  set ips [glob ip/*.xcix ip/*/*.xci]
  if { [llength $ips] } {
    # Read IP
    puts "Reading IP: $ips"
    read_ip $ips

    # Synthesize IPs, if necessary
    synth_ip [get_ips]
  }

  # Read block design
  set bds [glob src/bd/*/*.bd]
  if { [llength $bds] } {
    foreach bd $bds {
      puts "Reading block design: $bd"
      read_bd $bd
    }
  }

  # Read HDL files
  puts "Reading design sources"
  if ![catch {set vhdl_files [glob src/hdl/*.vhd src/hdl/vhdl/*.vhd]}] {
    read_vhdl -vhdl2008 $vhdl_files
  }

  if ![catch {set verilog_files [glob src/hdl/*.v src/hdl/verilog/*.v]}] {
    read_verilog [glob src/hdl/*.v]
  }

  # Read constraints
  puts "Reading constraints"
  read_xdc $synth_constraints

  if { $debug && [llength $debug_constraints] } { read_xdc $debug_constraints }
}

if { $run_to eq "" } { puts "Done."; return }

#########################
### Synthesize design ###
#########################
if { $start_from < 1 } {
  set now [clock format [clock seconds] -format %H:%M:%S]
  puts "Starting synth_design at $now"

  synth_design -top $top -part $part -flatten rebuilt

  if { $write_dcp} { write_checkpoint -force $output_dir/${top}_synth }

  if { $create_reports } {

    report_timing_summary -file $output_dir/${top}_synth_timing_summary.rpt
    report_bus_skew -file $output_dir/${top}_synth_bus_skew.rpt

  }
} elseif { $start_from == 1 } {
    open_checkpoint $output_dir/${top}_synth.dcp
}

if { $run_to eq "synth" } { puts "Done."; return }

########################
### Implement design ###
########################
if { $start_from < 2 } {
  # Read implementation specific constraints
  puts "Reading implementation-specific constraints"
  read_xdc $impl_constraints

  # Source tcl file from QoR suggestions to help with congestion
  # source -notrace scripts/RQSPreImpl.tcl

  set now [clock format [clock seconds] -format %H:%M:%S]
  puts "Starting opt_design at $now"

  opt_design

  if { $write_dcp } { write_checkpoint -force $output_dir/${top}_opt }
} elseif { $start_from == 2 } {
  open_checkpoint $output_dir/${top}_opt.dcp
}

if { $run_to eq "opt" } { puts "Done."; return }

####################
### Place design ###
####################
if { $start_from < 3 } {
  set now [clock format [clock seconds] -format %H:%M:%S]
  puts "Starting place_design at $now"

  place_design

  if { $write_dcp } { write_checkpoint -force $output_dir/${top}_placed }
  set now [clock format [clock seconds] -format %H:%M:%S]
  puts "Starting phys_opt_design at $now"

  phys_opt_design

  if { $write_dcp } { write_checkpoint -force $output_dir/${top}_placed_phys_opt }
  if { $create_reports } {

    report_timing_summary -file $output_dir/${top}_placed_phys_opt_timing_summary.rpt

  }
} elseif { $start_from == 3 } {
  open_checkpoint $output_dir/${top}_placed.dcp
}

if { $run_to eq "place" } { puts "Done."; return }

####################
### Route design ###
####################
if { $start_from < 4 } {
  if { $incr_checkpoint ne "" } {
    read_checkpoint -incremental $incr_checkpoint
  }

  set now [clock format [clock seconds] -format %H:%M:%S]
  puts "Starting route_design at $now"

  route_design

  if { $write_dcp } { write_checkpoint -force $output_dir/${top}_routed }

  report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 100 -routable_nets -file $output_dir/${top}_routed_timing_summary.rpt

  if { $create_reports } {

    report_timing -delay_type min_max -sort_by group -max_paths 100 -input_pins -routable_nets -file $output_dir/${top}_routed_timing.rpt
    report_clock_utilization -file $output_dir/clock_util.rpt
    report_utilization -file $output_dir/${top}_routed_util.rpt
    report_power -advisory -file $output_dir/${top}_routed_power.rpt
    report_drc -file $output_dir/${top}_routed_drc.rpt
    report_bus_skew -file $output_dir/${top}_routed_bus_skew.rpt

  }

  write_vhdl -force $output_dir/${top}_impl_netlist.vhd
  write_xdc -no_fixed_only -force $output_dir/${top}_impl.xdc
} elseif { $start_from == 4 } {
  open_checkpoint $output_dir/${top}_routed.dcp
}

set WNS [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "Post-route WNS = $WNS\n"

if { $run_to eq "route" } { return }

# If timing is just barely failing, try a post-route phys opt
if { $WNS < 0 && $WNS > -0.5 } {
  puts "Running post-route phys_opt"
  # Re-run physical optimization to try and meet timing

  phys_opt_design -directive AggressiveExplore

  if { $write_dcp } { write_checkpoint -force $output_dir/${top}_routed_phys_opt }

  report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 100 -routable_nets -file $output_dir/${top}_routed_phys_opt_timing_summary.rpt

}

##########################
### Generate bitstream ###
##########################
set now [clock format [clock seconds] -format %H:%M:%S]
puts "Starting write_bitstream at $now"
file mkdir bitstream

write_bitstream -force bitstream/$name.bit
write_debug_probes -force bitstream/$name.ltx

