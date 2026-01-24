### connection
```
iwctl
device list
station wlan0 get-networks
station wlan0 connect rete
exit
```
### install yay
[yay installation](https://cloudcone.com/docs/article/how-to-install-yay-helper-on-archlinux/)
### sway
to install only if you want to use sway
```
sudo pacman -S firefox foot grim pavucontrol slurp swayidle swaylock xorg-xwayland dmenu brightnessctl sway swaybg polkit thunar 
```
### linux for rog
[guide](https://asus-linux.org/guides/arch-guide/)
### nvidia
```
sudo pacman -S nvidia-open-dkms nvtop
```
### bluetooth
```
sudo pacman -S blueman bluez bluez-utils blueberry
systemctl enable bluetooth.service
systemctl start bluetooth.service
```
### hyprland
```
sudo pacman -S hyprland kitty xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk waybar hyprpaper slurp grim zip unzip filelight brightnessctl
yay -S tofi
```
### software
```
sudo pacman -S telegram-desktop whatsapp-for-linux htop spotify-launcher gnome-disk-utility gnome-calculator cheese loupe discord nemo cmatrix cava easyeffects mysql-workbench gimp libreoffice-fresh
```

```
yay -S google-chrome powerstat brave-bin whatsapp-for-linux zen-browser-bin
```
### jetbrains

[download](https://www.jetbrains.com/)
### git
```
sudo pacman -S git openssh rsync
systemctl --user enable ssh-agent.service
systemctl --user start ssh-agent.service
mkdir -p ~/.ssh
rsync -avh /Scaricati/.ssh/ ~/.ssh/
cp /Scaricati/.gitconfig ~/.gitconfig
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 644 ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts.old
ssh -T git@github.com
ssh -T git@gitlab.com
git --version
```
### dev
```
sudo pacman -S python-poetry pycharm-community-edition docker dbeaver netbeans gparted mysql-workbench
yay -S visual-studio-code-bin cursor-bin flutter zed-git docker-desktop lmstudio cursor-bin
```
### lamp
```
sudo pacman -S apache
sudo nano /etc/httpd/conf/httpd.conf
```
decomment:
```
#LoadModule unique_id_module modules/mod_unique_id.so
```

```
systemctl enable httpd
systemctl restart httpd
```

```
sudo nano /srv/http/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
</head>
<body>
    <p>test page</p>
</body>
</html>
```

```
sudo pacman -S mysql
sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
systemctl enable mysqld
systemctl start mysqld
sudo mysql_secure_installation
```

```
sudo pacman -S php php-apache
sudo nano /etc/httpd/conf/httpd.conf
```
comment:
```
LoadModule mpm_event_module modules/mod_mpm_event.so
```
aggiungere alla fine:
```
LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
LoadModule php_module modules/libphp.so
AddHandler php-script php
Include conf/extra/php_module.conf
```

```
sudo nano /srv/http/test.php
<?php
phpinfo();
?>
systemctl restart httpd
```
### shell

To install fish, run:
```
sudo pacman -S fish
```
To list all installed shells, run: 
```
chsh -l
```
And to set one as default for your user do:
```
chsh -s /bin/fish
```
Abbreviation:
```
abbr --add gco git checkout 
git checkout
```
Update completions:
```
fish_update_completions
```
Fish config:
```
fish_config
```
Remove greeting message:
```
set -U fish_greeting
```
### snapshot
[timeshift](https://wiki.archlinux.org/title/Timeshift)
```
sudo pacman -S timeshift grub-btrfs
systemctl enable --now grub-btrfsd.service
sudo grub-mkconfig -o /boot/grub/grub.cfg
```
### clipboard
```
sudo pacman -S wl-clipboard wl-clip-persist cliphist
```
### Logitech
```
yay -S logi-mx-bin
```
### Pacman cache
```
sudo systemctl enable --now paccache.timer
```
### Hyprland plugins
```
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm update
hyprmp list
hyprpm enable hyprexpo
```