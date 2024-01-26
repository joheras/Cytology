import sys
import tifffile
from skimage import io
from os import remove
import time

# Comprobacion ejecutar solo si se reciben 2 argumentos reales
if len(sys.argv) == 3:
    path = sys.argv[1]
    imageStack = sys.argv[2]
    im = io.imread(path+imageStack)
    title=imageStack.split('_')
    
    tif = tifffile.TiffFile(path+imageStack)
    nframes=len(tif.pages)
    page = tif.pages[0]
    with tifffile.TiffFile(path+imageStack) as tif:
    	tag = tif.pages[0].tags['IJMetadata']
    val=tag.value["Labels"]
    for n in range(nframes):
    	io.imsave(path+title[0]+"_"+val[n]+".tif",im[n])
    tif.close()
    del im

else:
    print("Error - Introduce los argumentos correctamente")
    print("Ejemplo: python script_name.py /path/to/directory/ my_image_stack.tif")

