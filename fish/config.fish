source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
    # smth smth
end


# Added by Antigravity CLI installer
set -gx PATH "$HOME/.local/bin" $PATH
alias clock="termdown"

# Minimal ls configuration (overriding default eza -al)
alias ls='eza --group-directories-first --icons=always'

# Custom Go path
set -gx GOPATH $HOME/.local/share/go
set -gx PATH $GOPATH/bin $PATH

# opencode
fish_add_path $HOME/.opencode/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

thefuck --alias | source
