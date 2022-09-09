# Arch-Install-Script  
These scripts install an [Arch Linux](https://archlinux.org/) base system alongside [Windows 11](https://www.microsoft.com/en-ca/windows/windows-11?r=1) or conduct a clean install on VM or SSD. The reader is still expected to have a very good understanding of the Arch Linux [Installation Guide](https://wiki.archlinux.org/title/Installation_guide). These scripts are only meant to automate the process for those who like me re-install Arch from scratch just for the heck of it. :-)    

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
4. Adjust the selected script to your specific hardware and requirements before using.  
5. Run one of the installation scripts:  
   ```
   ./install_base_arch_alongside_windows.sh
   ```
   or  
   ```
   ./install_base_arch.sh
   ```
