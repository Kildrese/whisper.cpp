#!/bin/bash

# Check if file path is provided
if [ -z "$1" ]; then
    echo "Usage: transcribe <path-to-audio-file> [language]"
    echo "Example: transcribe ~/Downloads/interview.mp3 de"
    echo "Example: transcribe ~/Downloads/interview.m4a en"
    echo ""
    echo "Supports: mp3, m4a, wav, mp4, and more"
    echo "Common language codes: en, de, es, fr, it, pt, nl, ja, zh, etc."
    echo "If no language is specified, auto-detection will be used."
    exit 1
fi

# Get the audio file path (convert to absolute path)
if [[ "$1" = /* ]]; then
    AUDIO_FILE="$1"
else
    AUDIO_FILE="$HOME/$1"
fi

# Get the language (default to auto-detect if not provided)
LANGUAGE="${2:-auto}"

# Check if file exists
if [ ! -f "$AUDIO_FILE" ]; then
    echo "Error: File not found: $AUDIO_FILE"
    exit 1
fi

# Get the directory and filename without extension
DIR=$(dirname "$AUDIO_FILE")
FILENAME=$(basename "$AUDIO_FILE" | sed 's/\.[^.]*$//')
EXTENSION="${AUDIO_FILE##*.}"

# Convert to WAV if not already WAV
if [ "$EXTENSION" != "wav" ]; then
    echo "Converting $EXTENSION to WAV format..."
    TEMP_WAV="$DIR/${FILENAME}_temp.wav"
    ffmpeg -i "$AUDIO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$TEMP_WAV" -y -loglevel error
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to convert audio file"
        exit 1
    fi
    
    AUDIO_TO_TRANSCRIBE="$TEMP_WAV"
    echo "Conversion complete!"
else
    AUDIO_TO_TRANSCRIBE="$AUDIO_FILE"
fi

# Set output path
OUTPUT_PATH="$DIR/${FILENAME}_transcript"

echo "Transcribing: $FILENAME"
if [ "$LANGUAGE" = "auto" ]; then
    echo "Language: Auto-detect"
else
    echo "Language: $LANGUAGE"
fi
echo "Model: large-v3-turbo (8x speed, near-large accuracy)"
echo "Output will be saved to: ${OUTPUT_PATH}.txt"
echo ""

# Build the command with whisper-cli
CMD="$HOME/Developer/spielerei/whisper.cpp/build/bin/whisper-cli -m $HOME/Developer/spielerei/whisper.cpp/models/ggml-large-v3-turbo.bin -f \"$AUDIO_TO_TRANSCRIBE\" -t 8 -otxt -osrt -of \"$OUTPUT_PATH\""

# Add language flag only if specified
if [ "$LANGUAGE" != "auto" ]; then
    CMD="$CMD -l $LANGUAGE"
fi

# Run whisper-cli
eval $CMD

# Clean up temporary WAV file
if [ "$EXTENSION" != "wav" ] && [ -f "$TEMP_WAV" ]; then
    rm "$TEMP_WAV"
    echo "Cleaned up temporary files"
fi

echo ""
echo "Transcription complete!"
echo "Text file: ${OUTPUT_PATH}.txt"
echo "Subtitle file: ${OUTPUT_PATH}.srt"
