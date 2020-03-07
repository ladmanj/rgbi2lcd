PROJ = rgbi2lcd
ADD_SRC = vga_timing.v
TST_SRC = `yosys-config --datdir/ice40/cells_sim.v`
SIM_FLAGS = -D sim

PIN_DEF = icebreaker.pcf
DEVICE = up5k
PACKAGE = sg48
include main.mk

