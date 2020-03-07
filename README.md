# rgbi2lcd

![result](https://github.com/ladmanj/rgbi2lcd/blob/master/rgbi2lcd_result.jpg)

This is a ZX Spectrum RGB+I video output to VGA LCD convertor.
It produces 640x480 60Hz output with pixeclock near to nominal 25.175 MHz.
It is configured to input input clock of ZX Spectrum +2/+3
~~~
F_PLLIN:    35.469 MHz (given)
F_PLLOUT:   25.175 MHz (requested)
F_PLLOUT:   25.124 MHz (achieved)
~~~
You need a parallel RGB LCD display, for example mine has input RGB666 - six bits per color.
It's up to you how to assign the four color bits of the Speccy to the output i.e. 18 bits.
This should be close to original: from MSB to LSB [RIRIRIGIGIGIBIBIBI], the intensity bit then
gives 42% of the whole brightness.

The verilog code is implemented in https://github.com/icebreaker-fpga/icebreaker board with iCE40 UltraPlus 5K.
The iCE40 UltraPlus 5K is interresting because the whole 16 kilowords of screenbuffer fits into it, besides the fact that there are opensource tools for this FPGA.
The tools are here https://github.com/cliffordwolf/icestorm

Install the tools and ther run make for building, make prog for the fpga programming, make sim for simulation.
For simulation you need to ungzip the RGBIS.hexval stimulus data file first.

![hardware](https://github.com/ladmanj/rgbi2lcd/blob/master/rgbi2lcd_hw.jpg)

Have fun!
