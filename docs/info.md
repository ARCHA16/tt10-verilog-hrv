<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project calculates the RMSSD (Root Mean Square of Successive Differences) value from a set of RR interval inputs. The input values are 8-bit digital RR intervals (in arbitrary units), and the module processes these to compute the RMSSD, which is a standard time-domain feature used to analyze heart rate variability (HRV).

The logic includes:
- Calculating the difference between successive RR values
- Squaring each difference
- Averaging the squared differences
- Taking the square root of that average

The output is an 8-bit RMSSD value.

## How to test

1. Reset the module by toggling `rst_n` low and then high.
2. Input a series of RR interval values (one at a time) through the `rr_in` signal.
3. Use the `valid` signal to indicate when the input is ready.
4. Wait for the `done` output to go high, which indicates the RMSSD output is ready.
5. Read the `rmssd_out` value as the result.

You can test the project either through simulation (Verilog testbench) or by loading the bitstream onto TinyTapeout hardware and sending values via GPIO.


## External hardware

None required for basic testing.
