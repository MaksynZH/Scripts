#!/bin/bash
sudo rm /var/crash/*
FILE="/etc/default/apport"
if grep -q "^enable=1" "$FILE"; then
    sudo sed -i 's/^enable=1/enable=0/' "$FILE"
else
    echo "enable=0" | sudo tee -a "$FILE" > /dev/null
fi
sudo systemctl disable appor
sudo systemctl stop appor
