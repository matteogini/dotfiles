#!/usr/bin/env python3
import os
import json
import configparser
from pathlib import Path

def get_apps():
    dirs = [
        Path("/usr/share/applications"),
        Path.home() / ".local/share/applications"
    ]
    apps = []
    seen = set()

    for d in dirs:
        if not d.exists():
            continue
        for f in d.glob("*.desktop"):
            if f.name in seen:
                continue
            seen.add(f.name)
            
            config = configparser.ConfigParser(interpolation=None)
            try:
                # Read without throwing errors on duplicate keys
                with open(f, 'r', encoding='utf-8') as file:
                    content = "[Desktop Entry]\n"
                    in_desktop_entry = False
                    for line in file:
                        if line.strip() == "[Desktop Entry]":
                            in_desktop_entry = True
                            continue
                        elif line.startswith("[") and in_desktop_entry:
                            in_desktop_entry = False
                            continue
                        
                        if in_desktop_entry and "=" in line:
                            content += line
                
                config.read_string(content)
                if not config.has_section("Desktop Entry"):
                    continue
                    
                entry = config["Desktop Entry"]
                if entry.get("NoDisplay", "false").lower() == "true":
                    continue
                    
                name = entry.get("Name")
                exec_cmd = entry.get("Exec")
                icon = entry.get("Icon", "application-x-executable")
                
                if name and exec_cmd:
                    # Clean up exec command (remove %f, %u, etc.)
                    exec_cmd = " ".join([p for p in exec_cmd.split() if not p.startswith("%")])
                    apps.append({"name": name, "cmd": exec_cmd, "icon": icon})
            except Exception:
                pass
                
    apps.sort(key=lambda x: x["name"].lower())
    print(json.dumps(apps))

if __name__ == "__main__":
    get_apps()
