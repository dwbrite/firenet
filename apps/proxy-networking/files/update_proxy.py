import time

import base64
import requests
from requests.exceptions import RequestException
from jinja2 import Template
from kubernetes.client import CoreV1Api, NetworkingV1Api, V1Secret
from kubernetes import config
import paramiko
from paramiko.ssh_exception import SSHException
from io import StringIO
import os

SECRET_NAME = os.getenv('SECRET_NAME', 'proxy-server-ssh-key')
SECRET_NAMESPACE = os.getenv('SECRET_NAMESPACE', 'default')
PROXY_HOST = os.getenv('PROXY_HOST', 'tiny.pizza')
PROXY_USER = os.getenv('PROXY_USER', 'root')

def create_ssh_client() -> paramiko.SSHClient:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    # Read SSH key from Secret
    v1 = CoreV1Api()
    secret: V1Secret = v1.read_namespaced_secret(SECRET_NAME, SECRET_NAMESPACE)
    private_key_value = secret.data["ssh-privatekey"]

    private_key_str = base64.b64decode(private_key_value).decode('utf-8')
    private_key_file_obj = StringIO(private_key_str)
    private_key = paramiko.RSAKey.from_private_key(private_key_file_obj)

    try:
        ssh.connect(PROXY_HOST, username=PROXY_USER, pkey=private_key)
    except SSHException as e:
        print(f"Failed to create SSH Client: {str(e)}")
        return None
    return ssh


def get_public_ip() -> str | None:
    try:
        return requests.get('http://ifconfig.me/ip').text.strip()
    except RequestException as e:
        print(f"Failed to get public IP: {str(e)}")
        return None


def update_nginx_config(ports, controller_ip: str) -> None:
    # Jinja2 format dict
    data = {"ports": ports, "controller_ip": controller_ip}

    # Define template
    template = Template("""
        events {}
        
        stream {
            {% for port in ports %}
            # 
            server {
                listen {{ port.port }};
                proxy_pass {{ controller_ip }}:{{ port.port }};
            }
            {% endfor %}
        }
    """)

    # Render template
    rendered = template.render(data)

    ssh_client = create_ssh_client()

    if ssh_client is None:
        return

    with ssh_client as ssh:
        with ssh.open_sftp() as sftp:
            try:
                with sftp.file('/config/nginx/nginx.conf', 'r', -1) as remote_file:
                    current_data = remote_file.read().decode()

                    if current_data == rendered:
                        return
            except IOError:
                print("/config/nginx/nginx.conf not found, attempting to write new file...")

            print(f"Change detected, updating config to: {rendered}")

            with sftp.file('/config/nginx/nginx.conf', 'w', -1) as remote_file:
                # let errors crash
                remote_file.write(rendered)

        # Reload nginx
        _, stdout, stderr = ssh.exec_command("docker exec nginx-proxy nginx -s reload")
        if stderr.channel.recv_exit_status() != 0:
            raise Exception(f"Nginx failed to reload configuration: {stderr.read().decode()}")

    print("Successfully updated and reloaded nginx configuration")


def main() -> None:
    # Load kube config
    config.load_incluster_config()

    v1 = CoreV1Api()

    service = v1.read_namespaced_service(namespace="default", name="nginx-ingress-controller")
    controller_ip = get_public_ip()

    if controller_ip is None:
        print("Failed to get Controller IP")
        return

    # Call update_nginx_config function
    update_nginx_config(service.spec.ports, controller_ip)


if __name__ == "__main__":
    print("Starting update_proxy.py. There may be no outputs until network configuration changes.")
    while True:
        main()
        time.sleep(60)
