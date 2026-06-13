local programs = {}

programs.terminal = "footclient"
programs.fileManager = "footclient yazi"
programs.menu = "quickshell ipc call qsIpc toggleAppLauncher"
programs.bar = "quickshell"
programs.rog = "rog-control-center"
programs.screenshot = 'grim -g "$(slurp)" - | wl-copy'
programs.browser = "zen-browser"
programs.powermenu = "quickshell ipc call qsIpc togglePowerMenu"
programs.lock = "hyprlock"
programs.note = "obsidian"
programs.dock = ""

return programs
