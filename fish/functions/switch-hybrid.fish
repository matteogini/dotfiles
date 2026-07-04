function switch-hybrid --wraps='supergfxctl -m Hybrid && loginctl terminate-user $USER' --description 'alias switch-hybrid supergfxctl -m Hybrid && loginctl terminate-user $USER'
    supergfxctl -m Hybrid && loginctl terminate-user $USER $argv
end
