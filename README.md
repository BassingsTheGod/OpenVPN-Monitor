## Features:
**Monitors OpenVPN Connections:**

- Tracks users who connect and disconnect from the OpenVPN server in real-time.

**Discord Webhook Notifications:**

- Sends connection and disconnection events to a Discord channel.
 
    Username

    Real IP (Spoiler Hidden)

    Uptime Monitor Link

    Total Connections By The User
    
    Server Location

    Server Uptime
    
    Connection Duration For Disconnections

    
**Configuration File Handling (config.txt):**

- Checks for the existence of /root/config.txt.

  - Creates it if missing with:
  
     webhook= (Discord webhook URL)
  
     uptime_monitor= (Uptime monitor link)

    server_location= (Server location)
  
 - Reads the webhook URL and uptime monitor link from the file.

**Tracks User Connection Counts:**

 - Logs how many times a user has connected.
 - Logs Connection Durations:

   - Records the start time of user sessions.
   - Calculates and logs the session duration when a user disconnects.
 
**Maintains Connection History:**

 - Logs connection and disconnection events in /root/history.txt.

**Detects Connection Changes:**

 - Compares the current connected users to the previous state.
 - Identifies new connections and disconnections.

**Monitors OpenVPN Status Log:**

 - Uses inotifywait to monitor /etc/openvpn/server/status.log for changes.
 - Detects real-time user connection changes.

**Error Handling and Logging:**

 - Checks if status.log exists before proceeding.
 - Provides success/error messages for configuration file handling and Discord webhook.
 - Logs all common errors within /root/debug.txt.

**Uses Temporary Files for Tracking:**

 - /tmp/current_users.txt – Stores currently connected users.

 - /tmp/previous_users.txt – Stores previously connected users.

 - /tmp/user_connection_counts.txt – Stores the number of times each user connected.

 - /tmp/user_connection_times.txt – Stores connection start times.

![image](https://github.com/user-attachments/assets/1a9e074f-9894-4253-a41f-b14e530239a5)


