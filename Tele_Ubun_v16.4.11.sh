#!/bin/bash

# Auto Config Teleport Agent Script

# Define server information
NAME="VPQH_AppQH_DB_Ecabinet_3"
SYSTEM="VPQH_AppQH"
IP="10.129.8.71"
IP_LOCAL="10.0.61.235"

# Teleport version and download URL
TELEPORT_VERSION="16.4.11"
TELEPORT_URL="https://cdn.teleport.dev/teleport_${TELEPORT_VERSION}_amd64.deb"
TELEPORT_DEB="teleport_${TELEPORT_VERSION}_amd64.deb"

# Install Teleport
echo "Downloading Teleport package..."
wget $TELEPORT_URL -q --show-progress

echo "Installing Teleport..."
sleep 1
chmod +x $TELEPORT_DEB
dpkg -i $TELEPORT_DEB
sleep 1

# Create teleport service configuration
echo "Configuring Teleport service..."
cat <<EOF > /lib/systemd/system/teleport.service
[Unit]
Description=Teleport SSH Service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5s
StartLimitInterval=0
EnvironmentFile=-/etc/default/teleport
ExecStart=/usr/local/bin/teleport start --pid-file=/run/teleport.pid --roles=node --token=f7adb7ccdf04037bcd2b554hjn343lk52ec6010fd6f0caec94ba190b765 --auth-server=vpublic.teleport.gpdn.net:443 --nodename=${NAME}_${IP} --labels=env=pro,system=${SYSTEM},type=server,ip=${IP},ip_public=${IP_LOCAL}
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/run/teleport.pid
LimitNOFILE=8192

[Install]
WantedBy=multi-user.target
EOF

# Set correct permissions for the service
chmod 751 /lib/systemd/system/teleport.service

# Check if the service file was created successfully
if [ ! -f /lib/systemd/system/teleport.service ]; then
    echo "ERROR: Teleport service configuration file not found!"
    exit 1
else
    echo "Teleport service configuration created successfully."
fi

# Add entry to /etc/hosts for the Teleport server
echo "Adding Teleport server to /etc/hosts..."
echo '10.129.8.4   vpublic.teleport.gpdn.net' >> /etc/hosts

# Reload systemd and start Teleport service
echo "Reloading systemd and starting Teleport service..."
systemctl daemon-reload
systemctl restart teleport
sleep 2

# Remove the old teleport data
rm -rf /var/lib/teleport

# Enable Teleport service to start on boot
systemctl enable teleport

# Check if the Teleport service is running
if ! systemctl is-active --quiet teleport; then
    echo "ERROR: Teleport Agent failed to start!"
    exit 1
else
    echo "Teleport Agent configured and running successfully."
fi

# Display the status of the Teleport service
systemctl status teleport

echo "Access Teleport web interface to verify the setup!"
