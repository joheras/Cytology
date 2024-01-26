import sys
import tifffile
from skimage import io
from os import remove
import time

# Comprobación de seguridad, ejecutar sólo si se reciben 2 argumentos reales
if len(sys.argv) == 3:
    path = sys.argv[1]
    imageStack = sys.argv[2]
    remove(path+imageStack)
    
else:
    print("Error - Introduce los argumentos correctamente")
    print("Ejemplo: python script_name.py /path/to/directory/ my_image_stack.tif")

