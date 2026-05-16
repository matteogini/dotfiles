local programs = {}

programs.terminal = "footclient"
programs.fileManager = "footclient yazi"
programs.menu = "tofi-drun --drun-launch=true"
programs.bar = "waybar"
programs.rog = "rog-control-center"
programs.screenshot = 'grim -g "$(slurp)" - | wl-copy'
programs.browser = "zen-browser"
programs.powermenu = "/home/matteo/.config/tofi/powermenu.sh"
programs.lock = "hyprlock"
programs.note = "obsidian"

return programs
