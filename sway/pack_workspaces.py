#!/usr/bin/env python3
import json
import subprocess

def run_swaymsg(cmd):
    return subprocess.check_output(['swaymsg', '-r'] + cmd).decode('utf-8')

def main():
    try:
        workspaces_json = run_swaymsg(['-t', 'get_workspaces'])
        workspaces = json.loads(workspaces_json)
    except Exception as e:
        print(f"Error getting workspaces: {e}")
        return

    # Keep track of active workspace
    active_ws_num = None
    nums = []

    for ws in workspaces:
        if ws.get('focused'):
            active_ws_num = ws['num']
        if ws.get('num', -1) > 0:
            nums.append(ws['num'])

    nums.sort()

    target = 1

    for num in nums:
        if num != target:
            print(f"Renaming workspace {num} to {target}")
            subprocess.run(['swaymsg', f'rename workspace number {num} to {target}'])
        target += 1

if __name__ == '__main__':
    main()
