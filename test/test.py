# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from PIL import Image


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Loading image...")
    img = Image.open("128x128_goku.png").convert("L") # "L" means 8-bit grayscale
    img.save("grayscale_input_test.png")
    width, height = img.size
    pixels = list(img.getdata()) # This makes a giant 1D list of pixel values
    output_pixels = [] # We will save our chip's answers here

    for i in range(height):
        for j in range(width):
            dut.ui_in.value = pixels[i*width + j]
            await ClockCycles(dut.clk, 1)
            if dut.uo_out.value[0] == 1 or dut.uo_out.value[0] == 0:
                output_int = dut.uo_out.value.integer
                output_pixels.append(output_int)
        dut.ui_in.value = 0
        await ClockCycles(dut.clk, 1)
        if dut.uo_out.value[0] == 1:
                output_int = dut.uo_out.value.integer
                output_pixels.append(output_int)


    dut._log.info("Saving image...")
    # Create a new blank grayscale image with the same dimensions
    out_img = Image.new("L", (width, height))
    
    # Pour your collected pixels into the image
    print(len(output_pixels))

    out_img.putdata(output_pixels[0:16383])
    
    # Save it to your folder
    out_img.save("output_image.png")
    dut._log.info("Done!")