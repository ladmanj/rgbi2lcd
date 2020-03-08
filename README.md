# rgbi2lcd

![result](https://github.com/ladmanj/rgbi2lcd/blob/master/rgbi2lcd_result.jpg)

This is a ZX Spectrum RGBI video output to VGA LCD convertor.

It was inspired by project Faudraj by David Lüftner http://www.8bit.8u.cz/Files/Faudraj/ (Czech only).

The convertor produces 640x480 60Hz output with pixeclock near to nominal 25.175 MHz.
This particular version is configured to input clock of ZX Spectrum +2/+3. 
You can adapt it for different models of Speccy or for different computer.
~~~
F_PLLIN:    35.469 MHz (given)
F_PLLOUT:   25.175 MHz (requested)
F_PLLOUT:   25.124 MHz (achieved)
~~~
You need a parallel RGB LCD display, for example mine has input RGB666 - six bits per color.
It's up to you how to assign the four color bits of the Speccy to the output i.e. 18 bits.
This should be close to original: from MSB to LSB [RIRIRIGIGIGIBIBIBI], the intensity bit then
gives 42% of the whole brightness.

Of course it can be adapted for different displays or to output to good old analog VGA or even DVI.
I just wanted to use the display i have.

The verilog code is implemented in https://github.com/icebreaker-fpga/icebreaker board with iCE40 UltraPlus 5K.
The iCE40 UltraPlus 5K is interresting because the whole 64 kilowords of screen buffer fits into it, besides the fact that there are opensource tools for this FPGA.
The tools are here https://github.com/cliffordwolf/icestorm

Install the tools and then run 
~~~ 
make 
~~~ 
for building, 
~~~ 
make prog 
~~~ 
for the fpga programming, or 
~~~
make sim 
~~~ 
for simulation.

For simulation you need to ungzip the RGBIS.hexval stimulus data file first.

Physical installation to the computer is depicted here http://www.8bit.8u.cz/Files/Faudraj/plus3-p.jpg.
The assignment of the signals to the FPGA ports is in the source code.

**Important: You must reduce the voltage levels from 5V to 3.3V.**
I'm using resistor dividers with 150R up and 300R down because then the output impedance is 100R. Originaly i was planning to match the impedance on the FPGA side with RC termination, but that was omitted in the end.

![hardware](https://github.com/ladmanj/rgbi2lcd/blob/master/rgbi2lcd_hw.jpg)

Have fun!
