.PHONY: help synth opt place route program_device project bd clean clean_bd clean_project clean_build

help:
	@echo "Available targets:"
	@echo "    bitstream            Create bitstream and probes. If optional argument DCP is provided"
	@echo "                         and points to a valid routed design checkpoint (.dcp) file,"
	@echo "                         perform incremental compile using that checkpoint as a reference"
	@echo "    bd                   Generate block design output"
	@echo "    synth                Synthesize the design, generating output reports and a checkpoint"
	@echo "    opt                  Run the design up to the optimzation step"
	@echo "    place                Run the design up to the place step"
	@echo "    route                Run the design up to the route step"
	@echo "    program_device       Program the board with the compiled bitstream"
	@echo "    test                 Run self-checking simulations"
	@echo "    project              Create a Vivado project"
	@echo "    clean                Delete .log and .jou files"
	@echo "    clean_bd             Delete block design output"
	@echo "    clean_project        Delete project directory"
	@echo "    clean_build          Delete build directory"
	@echo "    help                 Show this help"

synth opt place route bitstream: | bd
	$(eval ARGS = --run_to $@)
ifdef START_FROM
	$(eval ARGS = $(ARGS) --start_from $(START_FROM))
endif
ifdef DCP
	$(eval ARGS = $(ARGS) --incremental $(DCP))
endif
ifeq ($(DEBUG), 1)
	$(eval ARGS = $(ARGS) --debug)
endif
ifeq ($(FAST), 1)
	$(eval ARGS = $(ARGS) --fast)
endif
ifeq ($(NO_REPORT), 1)
	$(eval ARGS = $(ARGS) --no_report)
endif
	scripts/run_tcl build_design $(ARGS)

program_device: bitstream
	scripts/run_tcl program_device

test:
	scripts/test

project: proj

bd: src/bd

clean:
	rm -f *.{jou,log,pb}

clean_bd:
	rm -rf src/bd

clean_project:
	rm -rf proj

clean_build:
	rm -rf build

proj: | bd
	scripts/run_tcl create_project
	@echo "Archiving project output"
	tar czf project.tar.gz proj

src/bd:
	scripts/run_tcl create_bd
	@echo "Archiving block design output"
	tar czf bd.tar.gz src/bd
