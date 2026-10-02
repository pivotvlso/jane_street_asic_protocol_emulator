import os
import glob

def patch_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Patch spi_send_byte
    content = content.replace('#20 ui_in[1] = 1; #20 ui_in[1] = 0;', '#100 ui_in[1] = 1; #100 ui_in[1] = 0;')
    # Patch spi_read_byte
    content = content.replace('#20 ui_in[1] = 1; \n                data[i] = uo_out[0]; // Sample MISO\n                #20 ui_in[1] = 0;', '#100 ui_in[1] = 1; \n                data[i] = uo_out[0]; // Sample MISO\n                #100 ui_in[1] = 0;')
    content = content.replace('#20 ui_in[1] = 1; data[i] = uo_out[0]; #20 ui_in[1] = 0;', '#100 ui_in[1] = 1; data[i] = uo_out[0]; #100 ui_in[1] = 0;')
    
    with open(filepath, 'w') as f:
        f.write(content)

for filepath in glob.glob('tests/test_1_*.v'):
    patch_file(filepath)
