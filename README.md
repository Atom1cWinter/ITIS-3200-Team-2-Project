# Video Game Local Save-File Anti-Cheat System

This repository contains the GitHub deliverable for Team 2's ITIS 3200 course project. The project demonstrates a secure game state synchronization framework designed to protect player progress from unauthorized client-side modification.

> ⚠️ **Server Deployment Instructions:** > For detailed instructions on deploying the remote FastAPI security server (including VirtualBox OVA settings and ngrok tunneling), please refer to the [Server Deployment README](./server/README.md) located in the `server` directory.

---

## 1. System & Threat Model

### System Description
Modern video games frequently utilize local storage for player progression using accessible formats like JSON. Our system implements a **Server-Based Save Verification** mechanism to enforce data integrity. 
* **Users:** Primary users are game developers seeking robust anti-cheat solutions, and secondary users are players who value competitive fairness and narrative integrity.
* **Protected Assets:** Locally stored save files (`user://saves/secure_save.json`) containing progression data (current game level), inventory (coins, health), and unlockable abilities.

### Threat Model
* **Attacker Profile:** The end-user (player) attempting to gain an unfair advantage or skip intended gameplay progression.
* **Capabilities:** Full administrative access to the local file system. The attacker can read, write, modify, or delete JSON save files using standard text editors or custom scripts.
* **Assumptions:** We assume the local client (Godot) is fundamentally untrusted, but the remote server and its private key remain secure and confidential.
* **The Threat:** Data Tampering/Injection. Specifically, artificially inflating in-game currency or altering level progression variables without earning them in-game.

---

## 2. Security Mechanism & Justification

The primary security mechanism implemented is the generation and verification of **Hash-based Message Authentication Codes (HMAC-SHA256)** via a client-server architecture.

* **Implementation:** When the Godot client initiates a save, the raw data is sent to the FastAPI server. The server combines this data with a `SECRET_KEY` to generate an HMAC signature, which is returned and stored alongside the save data in `secure_save.json`. Upon loading, the process reverses: the server recalculates the hash and compares it to the stored signature.
* **Justification:** This mechanism directly addresses the threat of data tampering by securing the property of **Integrity**. By offloading the cryptographic operations to a remote server, we remove the vulnerability of storing the secret key within the game binary, preventing an attacker from reverse-engineering the key to forge valid signatures.

---

## 3. Implementation & Reproducibility (Running the Project)

To run these scenarios, ensure you have deployed the security server and updated the `SERVER_URL` in the Godot client as outlined in the `server/README.md`.

### The Secure System (Success Cases)
*This section demonstrates the correct behavior of the system, both during normal gameplay and when actively defending against an attack.*

#### Scenario A: Legitimate Gameplay (Normal Operation)
1. Launch the Godot game client.
2. Click **New Game** and complete the first level to accumulate progress (e.g., collecting 10 coins).
3. At the end of the level, proceed to save the game.
   * *Implementation Brief:* The client sends the stats to the server, receives the generated HMAC, and writes the `secure_save.json` file.
4. Return to the Start Menu and click **Load Game**.
5. **Result:** The server successfully verifies the signature. A `200 OK` response with `{"valid": true}` is returned, and the game loads the accurate player state.

#### Scenario B: Attack Interception (Defense Operation)
1. Close the Godot game.
2. Navigate to your local Godot user data folder and open the `saves` directory (e.g., `%APPDATA%\Godot\app_userdata\[Project Name]\saves\` on Windows).
3. Open `secure_save.json` in a text editor. Locate `"coins": 10` and manually change it to `"coins": 9999`. Save the file.
4. Launch the Godot game client and click **Load Game**.
5. **Result:** The server recalculates the HMAC using the tampered JSON string. The resulting hash does not match the stored signature. The server returns `{"valid": false}`.
6. **Impact Mitigation:** The client console triggers a `SECURITY ALERT: Save file was tampered with!` warning. The `SaveManager` rejects the fraudulent file and forces a load of default starting stats (0 coins), completely neutralizing the exploit.

### The Attack / Misuse (Failure Case)
*This demonstrates a concrete scenario where the security mechanisms fail due to removal or misuse, allowing data tampering to succeed.*

#### Scenario: Bypassed Verification Mechanism
1. **The Misuse:** The game developer decides to bypass the server for offline play, routing the save logic to generate an `unsecure_save.json` file that lacks an HMAC signature, or completely removes the `verify-hmac` API call from the load sequence.
2. **The Attack:** The player opens `unsecure_save.json` (or the unverified `secure_save.json`) in a text editor and modifies `"coins": 10` to `"coins": 9999`.
3. **Execution:** The player launches the game and loads the file.
4. **The Failure Result:** Because the HMAC verification mechanism is missing, the game client blindly parses the well-formed JSON. The player successfully spawns into the game with 9,999 coins.
5. **Impact:** The system has fundamentally failed. The security property of **Integrity** is destroyed, granting the attacker an unfair advantage and proving that the remote HMAC validation is strictly necessary to secure the game state.

---

## 4. Misuse Scenario Analysis (Local Key Storage)
A plausible but incorrect design choice would be calculating the HMAC locally using GDScript. Because the attacker has full access to the local machine, they could easily decompile the Godot binary, extract the hardcoded secret key, and write a Python script to generate valid HMACs for their forged save files. The client-server architecture is strictly necessary to prevent this specific key extraction vulnerability.
