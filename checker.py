#!/usr/bin/env python

import importlib
import subprocess
import sys
import os


if sys.version_info.major >= 3:
    print("Python is installed.")
    print("Version:", sys.version)
else:
    print("Python is not installed...Please install")
    sys.exit(5)

if os.environ.get('SHELL') and 'bash' in os.environ['SHELL']:
    print("Running in a Bash environment...proceeding")
else:
    print("Not running in a Bash environment...Please run in a bash shell")
    sys.exit(5)



def is_mobaxterm():
    if "MobaXterm.exe" in os.popen('tasklist').read():
        return True
    if os.environ.get('SSH_AUTH_SOCK'):
        return True
    
    return False


if is_mobaxterm():
    print("Running in MobaXterm environment.")
    isMoba=True
else:
    print("Not running in MobaXterm environment.")
    isMoba=False

if os.path.isfile('C:\Windows\System32\inetsrv\w3wp.exe'):
    print("IIS is installed !")
else:
    print("warning: IIS is not installed...some functions may not work")



def check_vboxmanage_installed():
    try:
        subprocess.run(['vboxmanage', '--version'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print("vboxmanage is installed on the system.")
    except subprocess.CalledProcessError:
        print("vboxmanage is not installed on the system or Env path is not set up")

check_vboxmanage_installed()


dependencies_python = []
dependencies_bash = ['jq']


for package in dependencies_python:
    try:
        importlib.import_module(package)
        print(f"The Python package '{package}' is already installed.")
    except ImportError:
        print(f"The Python package '{package}' is not installed. Installing...")
        subprocess.call(['pip', 'install', package])

for package_manager in dependencies_bash:
    try:
        subprocess.check_output(['which', package_manager])
        print(f"The Bash package '{package_manager}' is already installed.")
    except subprocess.CalledProcessError:
        print(f"The Bash package '{package_manager}' is not installed. Installing...")
        if  isMoba:
            subprocess.call(['apt', 'install', '-y', package_manager])
        else:
            print("Mobaxterm environment not detected...please install the required package manually")
            exit(5)