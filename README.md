# Video Game Local Save-File Anti-Cheat System
GitHub deliverable for Team 2's ITIS 3200 course project


🖥️ Server Deployment (Ubuntu VM)This project uses a dedicated Python FastAPI server to handle HMAC cryptographic signing. This ensures our secret key remains outside the game binary.1. Starting the ServerIf the server is offline, follow these steps to redeploy:Launch VirtualBox and start the HMAC-Signing-Server VM.Log in with your credentials.Check the IP Address:Baship addr show
Note: If the IP is not 192.168.18.40, you must update the SERVER_URL in SaveManager.gd in Godot.Navigate & Activate:Bashcd ~/sign-server
source venv/bin/activate
Run the API:Bashuvicorn main:app --host 0.0.0.0 --port 8000
2. Health CheckTo verify the server is reachable from your host machine, open a browser and visit:http://<VM_IP>:8000/healthYou should see: {"status": "online"}3. Running in Background (Optional)To keep the server running after closing your terminal window, use screen:Start: screen -S hmac_session -> Run the uvicorn command -> Press Ctrl+A then D.Re-attach: screen -r hmac_session🛠️ TroubleshootingIssueSolutionPermission Denied on sourceEnsure you are using the source command, not executing the file directly. If issues persist, run sudo chown -R $USER:$USER venv.Connection Timeout in GodotVerify the VM Firewall is open: sudo ufw allow 8000/tcp. Ensure the VM is using a Bridged Adapter in VirtualBox settings.Node Not Found (Godot)Ensure the SaveManager Autoload points to the .tscn file, not the .gd file.