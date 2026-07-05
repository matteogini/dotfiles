#!/bin/bash

MODES="Bounce\nSlash\nLoading\nBitStream\nTransmission\nFlow\nFlux\nPhantom\nSpectrum\nHazard\nInterfacing\nRamp\nGameOver\nStart\nBuzzer"

SELECTED=$(echo -e "$MODES" | tofi --prompt-text "Slash: ")

if [ -n "$SELECTED" ]; then
    asusctl slash --mode "$SELECTED" -l 255
fi
