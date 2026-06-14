#!/bin/bash
if pgrep -x "quickshell" > /dev/null; then
    quickshell ipc call qsIpc toggleControlCenter
fi
