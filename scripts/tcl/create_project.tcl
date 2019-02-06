# Set working directory to this script's parent directory
set root_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
cd $root_dir

# Read command line arguments, if present
if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    puts $option
    switch -regexp -- $option {
      "--name"              { incr i; set project_name [lindex $::argv $i] }
      "--top"               { incr i; set top [lindex $::argv $i] }
      "--part"              { incr i; set part [lindex $::argv $i] }
      "--synth_constraints" { incr i; set synth_constraints [split [lindex $::argv $i] ","] }
      "--impl_constraints"  { incr i; set impl_constraints [split [lindex $::argv $i] ","] }
      "--debug_constraints" { incr i; set debug_constraints [split [lindex $::argv $i] ","] }
      "--ip_repo_paths"     { incr i; set ip_repo_paths [split [lindex $::argv $i] ","] }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified.\n"
          return 1
        }
      }
    }
  }
}

create_project -part $part $project_name proj

set_property top $top [get_filesets sources_1]
set_property target_part $part -objects [get_filesets constrs_1]
set_property ip_repo_paths [file normalize $ip_repo_paths] [current_project]
update_ip_catalog -rebuild

add_files -fileset sources_1 [glob \
  src/hdl/*.vhd \
  src/hdl/*.v \
  src/bd/*/*.bd \
  ip/*/*.xci \
  ip/*.xcix \
]

add_files -fileset constrs_1 [glob \
  src/xdc/*.xdc \
]

set_property used_in_synthesis false [get_files $impl_constraints]

add_files -fileset sim_1 [glob \
  sim/*/*.vhd \
  sim/*/*.dat \
]

exit
