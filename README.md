## OpenVPN Server Monitor

***How To Use?***

Edit Your OpenVPN Configuration File: (Normally Located In: /etc/openvpn/server/server.conf)

Add These To The Server.conf File:

status /etc/openvpn/server/status.log

status-version 2


## Features

• **Real-Time Monitoring:** Monitors the OpenVPN server status log for any changes to user connections.

• **Discord Notifications:** Sends notifications to a specified Discord channel using webhooks for both connection and disconnection events.

• **User Connection Tracking:** Keeps track of total connections per user and records connection times.

• **Server Statistics:** Displays real-time server stats such as CPU load, available disk space, and memory usage.

• **Connection duration:** For disconnections, the script provides the connection duration.


![image](https://github.com/user-attachments/assets/52668b7f-1dfa-4141-9730-52cc2064b6b1)


![image](https://github.com/user-attachments/assets/f3f36026-814f-4a48-9c94-25c05799618d) ![image](https://github.com/user-attachments/assets/4316ba26-f513-40fe-9011-f18fb9bd43a4)

