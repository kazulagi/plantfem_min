import os
import sys
import platform


print("Detecting OS type...")
pf=platform.system()
if pf == 'Windows':
    print("OS : Windows")
    print("Now installing...")
    os.system("./SiCroF/SiCroF.bat")
    print("Please use Windows Subsystem Linux(WSL) ")
    print("Successfully Installed!!")
elif pf == "Darwin":
    print("OS : macOS")
    print("Now installing...")
    os.system("sh ./SiCroF/SiCroF_macOS")
    print("Successfully Installed!!")
elif pf == "Linux":
    print("OS : Linux")
    print("Now installing...")
    os.system("sh ./SiCroF/SiCroF")
    print("Successfully Installed!!")
else:
    print("OS : Unknown ")