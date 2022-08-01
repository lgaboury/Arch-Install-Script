# Arch-Insall-Script  
This script installs an Arch Linux base system alongside Windows.  
Assumes that partition nvme0n1p5 is used for the installation and will set existing nvme0n1p1 partition as ESP.  

## How to use  
1. Boot with Arch Linux ISO.
2. Connect to the internet.  With my wireless card, I use:
   ```
   iwctl station wlan0 connect <SSID>
   ```
   Replace ```<SSID>``` with your actual wifi SSID.
   
3. Clone this repository:  
   ```
   git clone https://github.com/lgaboury/Arch_install_Script.git
   ```
4. Go into Arch_Install_Script folder:  
   ```
   cd Arch_Install_Script
   ```
5. Run installation script:  
   ```
   ./install_base_arch_alongside_windows.sh
   ```
