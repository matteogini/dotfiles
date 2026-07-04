source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
    # smth smth
end


# Added by Antigravity CLI installer
set -gx PATH "/home/matteo/.local/bin" $PATH
alias clock="termdown"

# Custom Go path
set -gx GOPATH $HOME/.local/share/go
set -gx PATH $GOPATH/bin $PATH

# opencode
fish_add_path /home/matteo/.opencode/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
