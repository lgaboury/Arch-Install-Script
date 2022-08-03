# Arch-Install-Script  
This script installs an [Arch Linux](https://archlinux.org/) base system alongside [Windows 11](https://www.microsoft.com/en-ca/windows/windows-11?r=1).  
Assumes that partition nvme0n1p5 is used for the installation and will set existing nvme0n1p1 partition as ESP.  

## How to use  
1. Boot with Arch Linux ISO.
2. Connect to the internet.  With my wireless card, I use:
   ```
   iwctl station wlan0 connect <SSID>
   ```
   Replace ```<SSID>``` with your actual wifi SSID.
3. Update pacman databases:
   ```
   pacman -Sy
   ```
4. Install git:
   ```
   pacman -S git
   ```
   
3. Clone this repository:  
   ```
   git clone https://github.com/lgaboury/Arch-Install-Script.git
   ```
4. Go into Arch-Install-Script folder:  
   ```
   cd Arch-Install-Script
   ```
4. Make install script executable:
   ```
   chmod +x install_base_arch_alongside_windows.sh
   ```
5. Run installation script:  
   ```
   ./install_base_arch_alongside_windows.sh
   ```
