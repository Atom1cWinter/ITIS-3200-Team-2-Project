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
5. [cite_start]Once prompted, log in with the following credentials[cite: 1]:
   * [cite_start]**Username:** `vboxuser` [cite: 1]
   * [cite_start]**Password:** `password123` [cite: 1]
6. Once logged in, open a terminal and navigate to the server directory by running:
   ```bash
   cd ~/sign-server
   ```

## Option B: Deployment from Scratch (Ubuntu)
To set up the server environment from a fresh Ubuntu installation:

1. Update the package lists:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
2. Install Python 3, pip, venv, and tmux:
   ```bash
   sudo apt install python3 python3-pip python3-venv tmux -y
   ```
3. Create and activate a virtual environment, then install requirements:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install fastapi uvicorn
   ```
4. Download the server source code (`main.py`) into your desired directory (e.g., `~/sign-server`).

## Running the Server and ngrok Tunnel
Because the server needs to be reachable over the internet (bypassing local CGNAT/firewalls), we use ngrok to establish a TCP tunnel. It is highly recommended to use `tmux` to run both the server and ngrok side-by-side in a single, persistent terminal session.

### Method: Using tmux (Recommended)
`tmux` allows you to split your terminal screen and keep the server running safely in the background.

1. **Start a new tmux session:**
   ```bash
   tmux new -s hmac_server
   ```
2. **Start the FastAPI Server:**
   Navigate to the directory, activate the virtual environment, and run uvicorn:
   ```bash
   cd ~/sign-server
   source venv/bin/activate
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```
   *The server is now listening locally on port 8000.*
3. **Split the terminal and start ngrok:**
   * Press `Ctrl+B`, then `%` to split the screen vertically.
   * In the new right-hand pane, start the ngrok tunnel:
   ```bash
   ngrok tcp 8000
   ```
   *Note: ngrok will display a forwarding URL in the terminal (e.g., `tcp://2.tcp.ngrok.io:15081`).*
4. **Detach from the session (Optional):**
   * Press `Ctrl+B`, then `d` to safely detach. The server and tunnel will keep running in the background. 
   * To reconnect and view the logs later, run: `tmux attach -t hmac_server`

## Godot Client Configuration
Whenever the server is restarted or a new ngrok tunnel is created, the client must be updated to point to the new address.

1. Copy the forwarding URL provided by ngrok (excluding the `tcp://` prefix).
2. Open the Godot project and navigate to `save_manager.gd`.
3. Update the `SERVER_URL` constant, ensuring it uses the `http://` prefix:
   ```gdscript
   const SERVER_URL = "[http://2.tcp.ngrok.io:15081](http://2.tcp.ngrok.io:15081)"
   ```
