__***README Signing Server***__

To reimplement signing server (server is down, wanting to be moved, or you want to set it up for testing on your machine)
use the HMAC-Signing-Server.ova file found in the shared google drive.

Using Oracle VirtualBox, click *'File' > 'Import Appliance'* and add the HMAC-Signing-Server.ova in. 

- **BEFORE** hitting finish, **Change MAC address policy to 'Generate new MAC address or all new network adapters'**
- **BEFORE** hitting start: 
    Right-click the *HMAC-Signing-Server* and go to *Settings*.
    Go to the 'Network' tab
    Change *'Attached to'* to *'Bridged Adapter'*
    Under *'Name'* select **your personal active internet connection** (e.g. "Intel(R) Wi-Fi 6" or "Realtek PCIe Ethernet")

**Note**: You might want to change how much RAM and how many processors you'll allow it to access (The default should be 4096MB and 2 Processors).


The implemented server *should* contain all of the required plugins needed for the server and *should* contain the main.py file needed to run.
There should also be an included virtual environment needed to run the server.


***TO RUN THE SERVER***
- Run 'ip addr show' to find your IP address; update the 'SERVER_URL' constant in SaveManager.gd with this value (should start with 192.168.x.x)
- 'cd sign-server'
- 'source venv/bin/activate' to run your virtual environment
- Run 'uvicorn main:app --host 0.0.0.0 --port 8000' to start the API server and allow HMAC processing