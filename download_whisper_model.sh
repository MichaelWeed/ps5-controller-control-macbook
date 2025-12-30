#!/bin/bash

# Download Whisper Base Model Script
# Run this to download the base model to ~/.whisper-models/

# Create directory
mkdir -p ~/.whisper-models

# Download using the whisper.cpp models script
cd ~/.whisper-models

# Method 1: Use bash download script from whisper.cpp repo
curl -L https://raw.githubusercontent.com/ggerganov/whisper.cpp/master/models/download-ggml-model.sh | bash -s base

# OR Method 2: Direct download (if Method 1 fails)
# wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin

echo "Model downloaded to ~/.whisper-models/"
echo "To use it, update whisper_dictation.sh:"
echo "WHISPER_MODEL=\"$HOME/.whisper-models/ggml-base.bin\""
