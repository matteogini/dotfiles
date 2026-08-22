#!/bin/bash
# Wait for desktop session to settle (timer handles 30s delay), then auto-detect and apply power limit
/usr/local/bin/setwatt auto > /tmp/setwatt.log 2>&1
