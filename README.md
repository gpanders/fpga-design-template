# FPGA Design Template

FPGA project design template for use with Xilinx Vivado.

## Introduction

This project serves as a template for Xilinx based FPGA projects. Currently,
only Linux is supported.

The motivation of this project was to get away from being constrained by
Vivado's clunky GUI. While the Vivado GUI is often useful and sometimes
necessary, most of the time it is not, and there are significant speed and
productivity improvements to be had by moving to a scripted command-line flow.

Organizing the project as a software project allows us to leverage many of the
tools that software developers have been using for years, such as version
control, release tagging, and automated testing.

## Design Flow

Define your project settings such as project name, part, top level module,
and constraints files in `settings.conf`.

The `Makefile` is the entry point for executing all tasks. Running `make help`
will provide a list of all available targets. Each target in turn sources a 
Tcl script (found in the `scripts/tcl` directory) which uses the settings
specified in `settings.conf` to build the design.

The Tcl scripts look for all source files under the `src` directory.
HDL design files should go under `src/hdl/`, block designs should go in
`src/bd/<bd_name>/`, and constraints under `src/xdc/`.

**Constraints file are not read as globs and must be explicitly specified in the
settings.conf file**. This is because it is Xilinx's recommended best practice
to separate synthesis constraints from implementation constraints (see [Vivado
User Guide: Using
Constraints](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/ug903-vivado-using-constraints.pdf)).
All other source files are read as globs, meaning if the file exists under 
`src/` it will be read.

Once all of your source design files, constraints, and IP are ready, you can
create a bitstream using

```shell
make bitstream
```

And you can program the device using

```shell
make program_device
```

The Makefile also provides other targets for design analysis. See `make help`
for all options.

## Creating a Project

The make-based workflow is designed to work in non-project flow. Non-project
flow has many benefits, not the least of which is speed; however, there are 
some things that are either much easier to do in project mode or that _must_ be
done in project mode. For that purpose, you can easily create a project from
your design sources using

```shell
make project
```

This will create a Vivado project under the `proj` directory.

## Managing IP

Following Xilinx's recommendations, this design utilizes a managed IP project
to generate and manage all project IP. To create IP for use in your design,
open the managed IP project in Vivado and create and configure your IP from the
IP catalog. Be sure that your IP is created in the `ip/` directory (this is the
default). The Tcl build scripts look for IP files (either `.xci` or `.xcix`)
underneath this directory.

See chapter 3, "Using Manage IP Projects" of [Vivado User Guide: Designing With
IP](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_1/ug896-vivado-ip.pdf)
for more information.

## Simulating and Testing

The `sim` directory contains files for simulation. Each module to be simulated should
exist in its own directory, and each directory should contain a `.prj` file
enumerating the source files used in that module and a top-level HDL testbench
file. The test bench should should be self-checking and should fail (i.e. using
an assert statement) if the simulation does not match expected output.

Example:

    sim/
    --+ my_module/
    ----+ my_module.prj
    ----+ my_module_tb.vhd
    ----+ golden_data.dat
    ----+ input_data.dat
