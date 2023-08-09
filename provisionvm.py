#!/usr/bin/env python

import sys
import os
import subprocess
import signal
import time



def signal_handler(sig, frame):
    print("Exiting, please wait...")
    for i in range(1, len(arguments)):
        vm_name = arguments[i]
        commands = [f'vboxmanage controlvm {vm_name} poweroff 2>>{path}/vboxlogs', f'vboxmanage unregistervm {vm_name} --delete-all 2>>{path}/vboxlogs']
        for command in commands:
            exit_code = os.system(command)
            time.sleep(5)
            if exit_code == 0:
                print("Command executed successfully.")
            else:
                time.sleep(5)
                os.system(command)
        

signal.signal(signal.SIGINT, signal_handler)

arguments = sys.argv
path = os.getcwd()
executable_path = os.path.abspath("newVM.sh")
for i in range(1, len(arguments)):
    arg = (f"{arguments[i]}")
    print(arg)
    command = (f"cd {path} && {executable_path} {arg}")
    os.system(f'"MobaXterm.exe" -newtab "{command}"')
    # process = subprocess.Popen([path, "-newtab", "-exec", command])
    # process = subprocess.Popen(f'{executable_path} {arg}', shell=True, executable="/bin/bash")
    # tasks.append(process)

# for process in tasks:
#     process.wait()

script_path = 'ssh-flask.py'
subprocess.run(['py', script_path])

