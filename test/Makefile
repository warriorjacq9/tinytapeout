# Makefile

# defaults
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = project.v

COMPILE_ARGS = -g2005-sv

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD				= sim/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

SIM_LOG					= $(SIM_BUILD)/sim.log

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.sv
TOPLEVEL = tb

# MODULE is the basename of the Python test file
MODULE = test

all: test

run: test
ifeq ($(GATES), yes)
	gtkwave tb.vcd config.gtkw
else
	gtkwave tb_rtl.vcd rtl.gtkw
endif

clean:
	rm -rf sim tb.vcd results.tap

test:
	mkdir -p $(SIM_BUILD) 
	iverilog $(COMPILE_ARGS) -o $(SIM_BUILD)/sim.vvp -s $(TOPLEVEL) $(VERILOG_SOURCES)
	vvp $(SIM_BUILD)/sim.vvp | tee $(SIM_LOG) | ./tapview
	tail -n +2 $(SIM_LOG) > results.tap
	@if grep -q "not ok" $(SIM_LOG); then \
	    echo "Errors detected in Verilog simulation!"; \
	    exit 1; \
	fi