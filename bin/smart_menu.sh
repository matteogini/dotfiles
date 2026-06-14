#!/bin/bash
if pgrep -x "quickshell" > /dev/null; then
    # Performance Mode: Use Quickshell IPC
    quickshell ipc call qsIpc toggleAppLauncher
else
    # Battery Mode: Fallback to Tofi/Legacy
    tofi-drun --drun-launch=true
fi
