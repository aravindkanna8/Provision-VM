from flask import Flask, request
import paramiko
import subprocess
import json
import sys
import socket
import os
import ssl

app = Flask(__name__)
path = os.getcwd()

def get_wifi_ip():
    # Get the hostname of the machine
    hostname = socket.gethostname()

    # Get the IP address associated with the hostname
    ip_address = socket.gethostbyname(hostname)
    # print (ip_address)
    return ip_address

# def read_local_file():
#     file_path = 'secret_num.txt'
#     with open(file_path, 'r') as file:
#         local_value = file.read().strip()
#         # number = local_value.split(':')[1].strip()
#     return local_value

@app.route('/send-file/<vm_name>', methods=['GET','POST'])
def send_file(vm_name):
    header_value = request.headers.get('X-Value')
    # requester_ip = request.remote_addr
    # local_value = read_local_file()
    with open(f'{path}/vms/{vm_name}/secret_num.txt', 'r') as file:
            local_value = file.read().strip()

    # return local_value
    if header_value == local_value:
        # Place the code for sending SSH key files here
        username = 'root'

        with open('config.json', 'r') as file1:
            data1 = json.load(file1)
        password = data1['clone']['root_pswd']
        server_key_path = data1['sshops']['ssh_path']

        with open(f'{path}/vms/{vm_name}/{vm_name}.json', 'r') as file:
            data = json.load(file)
        hostname = data['network']['ip']
        cluster = data['cluster']['cluster']
        cluster_mode = data['cluster']['cluster_mode']

        with open(f'{path}/vms/{vm_name}/post.txt', 'w') as file:
            file.write("Post Script is running...")


        try:
            ssh_client = paramiko.SSHClient()
            ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh_client.connect(hostname=hostname, username=username, password=password)
            sftp_client = ssh_client.open_sftp()

            if cluster == "True":
                if cluster_mode == "new":
                    ycp_path = f'{path}/vms/{vm_name}/newclustermacro.ycp'
                    ycp_path_destination_path = '/root/newclustermacro.ycp'
                else:
                    ycp_path = f'{path}/vms/{vm_name}/existingclustermacro.ycp'
                    ycp_path_destination_path = '/root/existingclustermacro.ycp'
                sftp_client.put(ycp_path, ycp_path_destination_path)

            signed_file_path = f'{server_key_path}/{vm_name}/{vm_name}-cert.pub'
            destination_path = f'/etc/ssh/{vm_name}-cert.pub'

            pub_key_path = f'{server_key_path}/{vm_name}/{vm_name}.pub'
            pub_key_destination_path = f'/etc/ssh/{vm_name}.pub'

            private_key_path = f'{server_key_path}/{vm_name}/{vm_name}'
            private_key_destination_path = f'/etc/ssh/{vm_name}'

            ca_file_path = f'{server_key_path}/ca-keys/ca-auth.pub'
            ca_dest_path = f'/etc/ssh/ca-auth.pub'

            sftp_client.put(pub_key_path, pub_key_destination_path)
            sftp_client.put(private_key_path, private_key_destination_path)
            sftp_client.put(signed_file_path, destination_path)
            sftp_client.put(ca_file_path, ca_dest_path)

            sftp_client.close()
            ssh_client.close()

            return 'Host keys sent successfully........'

        except paramiko.AuthenticationException:
            return 'Authentication failed. Please check your credentials.'
        
        except paramiko.SSHException as e:
            return 'An error occurred during SSH connection: ' + str(e)

        except subprocess.CalledProcessError as e:
            return 'An error occurred during signing or editing sshd_config: ' + str(e)

        except Exception as e:
            return 'An unexpected error occurred: ' + str(e)

    else:
        return 'Secret key didnot match.....SSH didnt configure......'

if __name__ == '__main__':
    # app.run(host=get_wifi_ip())
    # app.run(host="0.0.0.0")

    # Load SSL certificate and key files
    context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
    context.load_cert_chain(certfile=f'{path}/openssl/cert.pem', keyfile=f'{path}/openssl/cert-key.pem')

    # Run the Flask application with HTTPS enabled
    app.run(host='0.0.0.0', port=6443, ssl_context=context)
 