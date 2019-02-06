# FPGA Design Template

## Directory structure

### src

Contains subdirectories `hdl`, `bd`, and `xdc`. The `hdl` directory can
(optionally) be further subdivided into `vhdl`, `verilog`, and `sv` directories
if the design contains sources using multiple languages.

**NOTE:** It is _strongly_ recommended to generate the block design as
Out-of-Context per Block Design from within the dummy project. Then copy all of
the generated products to the `src/bd` directory. This allows the Tcl build
script to simply read in the block design without regenerating anything.
Alternatively, you can generate the block design as Global and add the
following to the Tcl build script after the `read_bd` command:

    generate_target all [get_files src/bd/<your_bd_name>/<your_bd_name>.bd]

Depending on the size and complexity of your block design, this will add
considerable runtime to the build.

### ip

Contains the `managed_ip_project` from which the user can generate any required
IP for the design. Using Core Containers is recommended, but not required. When
IP is required, commit the entire IP folder (or .xcix file if using core
containers) for each IP, as well as the `ip_user_files` directory.

### sim

Contains all simulation and test bench files.

### scripts

Contains Tcl, shell (bash), and batch (Windows) scripts for building the design
as well as programming the device with the generated bitstream.

## Building the design

### The Easy Way

```shell
make bitstream
```

### Details

The script `build` is the main driver of the build process. This script accepts
the following command line arguments:

    --start_from  <step>
                    If omitted, start the build process from the very
                    beginning. Otherwise, open the checkpoint generated after 
                    step <step> from a previous build, where <step> is one of
                    'synth|opt|place|route' 

    --run_to <step>
                    If omitted, run all the way to the 'write_bitstream' step.
                    Otherwise, stop after completing <step>, where <step> is
                    one of 'synth|opt|place|route'

    --incremental <checkpoint file>
                    Use the incremental compile flow with the provided 
                    reference checkpoint file

    --no_report
                    Do not create reports (note that the timing summary report
                    is created regardless after the route_design step, per
                    Vivado requirements)

    --no_debug     
                    Disable debug mode. This option will prevent the build
                    script from reading in any user-specified debug-specific
                    constraints

    --fast  
                    Disable writing design checkpoints as well as writing
                    reports. Not recommended.

Both the bash script and the batch script act as wrappers around the Tcl
script and contain similar arguments.

### program_device.tcl

This script writes the bitstream to the connected FPGA. The user _must_ 
configure this script prior to running it the first time to set the proper
part/board name.

## Creating IP

To create IP to use in the design, open the `managed_ip_project` and create
IP there. Be sure to use a remote location for IP (i.e. the ip/ directory) 
and do not save new IP as "Local to Project". This should be the default
setting.

*NOTE*: When you first clone the template, you must update the part in the 
`managed_ip_project` project settings.

Using core container is recommended but not necessary. Once new IP is created,
there should be either a folder or a `.xcix` file in the `ip/` directory.
You can either use a glob to match all IP in the `ip/` directory or you can
enumerate the IP to use in the design explicitly (recommended). You will find
these options in the User Configuration section of the `build.tcl` script.
