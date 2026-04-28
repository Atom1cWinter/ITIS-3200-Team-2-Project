# Server Deployment Guide - HMAC Security Server

This repository contains the deployment instructions and environment configuration for the FastAPI security server used to generate and verify HMAC-SHA256 signatures for Godot game saves.

## Option A: Redeployment via OVA (VirtualBox)
If you were provided with the pre-configured `.ova` image, follow these steps to import and run the server environment:

1. Open Oracle VM VirtualBox.
2. Go to **File > Import Appliance** and select the provided `.ova` file.
3. Keep the default import settings, but ensure the following specifications are met for optimal performance:
   * **RAM:** 2048 MB (2 GB) minimum.
   * **CPU:** 2 Cores.
   * **Network Adapter:** Set to **Bridged Adapter** (or NAT with port forwarding for port 8000 if Bridged is unavailable on your network).
4. Click **Finish** and start the Virtual Machine.
5. Once prompted, log in with the following credentials:
   * **Username:** `vboxuser`
   * **Password:** `password123`
6. Once logged in, open a terminal and navigate to the server project directory.

## Option B: Deployment from Scratch (Ubuntu)
To set up the server environment from a fresh Ubuntu installation:

1. Update the package lists:
   ```bash
   sudo apt update && sudo apt upgrade -y
Install Python 3 and pip:

Bash
sudo apt install python3 python3-pip -y
Install the required Python libraries for the server:

Bash
pip install fastapi uvicorn
Download the server source code (main.py) into your desired directory.

Running the Server and ngrok Tunnel
Because the server needs to be reachable over the internet (bypassing local CGNAT/firewalls), we use ngrok to establish a TCP tunnel.

Start the FastAPI Server:
In your terminal, navigate to the directory containing main.py and run:

Bash
uvicorn main:app --host 0.0.0.0 --port 8000
The server is now listening locally on port 8000.

Establish the ngrok TCP Tunnel:
Open a second terminal window and run:

Bash
ngrok tcp 8000
Note: ngrok will display a forwarding URL in the terminal (e.g., tcp://2.tcp.ngrok.io:15081).
