

#!/bin/bash

# Auto Config Teleport Agent Script

# Define server information
NAME="CongDanSo_POC_DB2"
SYSTEM="CongDanSo_POC"
IP_PUBLIC="117.5.149.119"
IP_LOCAL="10.129.8.34"

# Teleport version and download URL (commented out for now)
 TELEPORT_VERSION="16.4.11"
 TELEPORT_RPM_URL="https://cdn.teleport.dev/teleport-${TELEPORT_VERSION}-1.x86_64.rpm"

# Install Teleport (commented out)
 echo "Downloading Teleport package..."
 wget $TELEPORT_RPM_URL -q --show-progress
 echo "Installing Teleport..."
 sleep 1
 chmod +x teleport-${TELEPORT_VERSION}-1.x86_64.rpm
 rpm -U teleport-${TELEPORT_VERSION}-1.x86_64.rpm
 sleep 1

# Create teleport service configuration
echo "Creating Teleport service configuration..."
cat <<EOF > /usr/lib/systemd/system/teleport.service
[Unit]
Description=Teleport SSH Service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5s
StartLimitIntervalSec=0
EnvironmentFile=-/etc/default/teleport
ExecStart=/usr/local/bin/teleport start --pid-file=/run/teleport.pid --roles=node --token=f7adb7ccdf04037bcd2b554hjn343lk52ec6010fd6f0caec94ba190b765 --auth-server=vpublic.teleport.gpdn.net:443 --nodename=${NAME}_${IP_LOCAL} --labels=env=pro,system=${SYSTEM},type=server,ip_public=${IP_PUBLIC},ip=${IP_LOCAL}
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/run/teleport.pid
LimitNOFILE=8192

[Install]
WantedBy=multi-user.target
EOF

# Set correct permissions for the service
chmod 751 /usr/lib/systemd/system/teleport.service

# Check if the service file was created successfully
if [ ! -f /usr/lib/systemd/system/teleport.service ]; then
    echo "ERROR: Teleport service configuration file not found!"
    exit 1
else
    echo "Teleport service configuration created successfully."
fi

# Add Teleport server entry to /etc/hosts
echo "Adding Teleport server entry to /etc/hosts..."
echo '10.129.8.4   vpublic.teleport.gpdn.net' >> /etc/hosts

#Remove  old verison teleport data
rm -rf /var/lib/teleport

# Reload systemd and start the Teleport service
echo "Reloading systemd and starting Teleport service..."
systemctl daemon-reload
systemctl restart teleport
sleep 5

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

echo "Access the Teleport web interface to verify the setup!"


