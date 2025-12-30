#!/bin/zsh

# Voice Dictation with Whisper (Hold-to-Record Version)
# Usage: Run this script from BetterTouchTool

# Configuration
TEMP_DIR="${TMPDIR:-/tmp}/whisper_dictation"
AUDIO_FILE="$TEMP_DIR/recording.wav"
TRANSCRIPTION_FILE="${AUDIO_FILE}.txt"
PID_FILE="$TEMP_DIR/sox.pid"

# Paths
SOX_PATH="/opt/homebrew/bin/sox"
WHISPER_PATH="/opt/homebrew/bin/whisper-cli"
WHISPER_MODEL="$HOME/.whisper-models/ggml-base.bin"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Cleanup function
cleanup() {
    rm -f "$AUDIO_FILE" "$TRANSCRIPTION_FILE" "$PID_FILE"
}

# Check if we're stopping a recording
if [ -f "$PID_FILE" ]; then
    echo "Stopping recording..."
    SOX_PID=$(cat "$PID_FILE")
    
    # Send SIGINT to sox
    kill -INT $SOX_PID 2>/dev/null
    
    # Wait for sox to finish writing the file
    sleep 1
    
    # Remove PID file
    rm -f "$PID_FILE"
    
    # Check if recording exists
    if [ ! -f "$AUDIO_FILE" ] || [ ! -s "$AUDIO_FILE" ]; then
        echo "Error: Recording failed or is empty"
        cleanup
        exit 1
    fi
    
    # Transcribe with whisper-cpp
    echo "Transcribing..."
    $WHISPER_PATH -m "$WHISPER_MODEL" -otxt "$AUDIO_FILE" 2>/dev/null
    
    # Read transcription
    if [ ! -f "$TRANSCRIPTION_FILE" ]; then
        echo "Error: Transcription failed"
        cleanup
        exit 1
    fi
    
    TRANSCRIPTION=$(cat "$TRANSCRIPTION_FILE" | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Developer-specific text replacements
    TRANSCRIPTION=$(echo "$TRANSCRIPTION" | sed -E '
        s/\bfire base\b/firebase/gi
        s/\bgit hub\b/github/gi
        s/\bgit lab\b/gitlab/gi
        s/\bpost gres\b/postgres/gi
        s/\bmy sequel\b/mysql/gi
        s/\bmongo d b\b/mongodb/gi
        s/\bred is\b/redis/gi
        s/\btype script\b/typescript/gi
        s/\bJava Script\b/javascript/gi
        s/\bdocker compose\b/docker-compose/gi
        s/\band and\b/\&\&/g
        s/\bor or\b/||/g
        s/\bdash dash\b/--/g
        s/\bequals equals\b/==/g
        s/\bnot equals\b/!=/g
        s/\bgreater than or equal\b/>=/g
        s/\bless than or equal\b/<=/g
        s/\bplus plus\b/++/g
        s/\bminus minus\b/--/g
        s/\bsemi colon\b/;/g
        s/\bopen paren\b/(/g
        s/\bclose paren\b/)/g
        s/\bopen brace\b/{/g
        s/\bclose brace\b/}/g
        s/\bopen bracket\b/[/g
        s/\bclose bracket\b/]/g
    ')
    
    # Show notification before typing
    osascript -e "display notification \"Typing transcription...\" with title \"Whisper Dictation\""
    
    # Type the text into the frontmost application
    osascript -e "tell application \"System Events\" to keystroke \"$TRANSCRIPTION\"" 2>/dev/null
    
    # Cleanup
    cleanup
    
    echo "Dictation complete!"
    
else
    # Start recording in background
    echo "Starting recording..."
    
    # Start sox in background
    $SOX_PATH -d -r 16000 -c 1 -b 16 "$AUDIO_FILE" >/dev/null 2>&1 &
    
    # Save sox PID
    echo $! > "$PID_FILE"
    
    echo "Recording... (Run script again to stop and transcribe)"
fi
