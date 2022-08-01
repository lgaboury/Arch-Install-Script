# Arch-Insall-Script

echo
echo "Enabling wifi..."
read -p "Enter wifi SSID: " ssid
iwctl station wlan0 connect $ssid
sleep 5
