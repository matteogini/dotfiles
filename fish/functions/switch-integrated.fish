function switch-integrated --wraps='supergfxctl -m Integrated && loginctl terminate-user $USER' --description 'alias switch-integrated supergfxctl -m Integrated && loginctl terminate-user $USER'
    supergfxctl -m Integrated && loginctl terminate-user $USER $argv
end
