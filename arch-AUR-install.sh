sudo pacman -Syu
sudo pacman -S git base-devel
cd
mkdir AUR
cd AUR
git clone https://aur.archlinux.org/timeshift.git
cd timeshift/
makepkg -sri

cd
cd AUR
git clone https://aur.archlinux.org/kdeplasma-applets-gmailfeed.git
cd kdeplasma-applets-gmailfeed/
makepkg -sri
