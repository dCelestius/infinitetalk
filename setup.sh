#!/bin/bash

# Full ComfyUI + InfiniteTalk + WanVideoWrapper + MultiTalk setup script for RunPod
# Updated September 2025 - Optimized for RunPod's /workspace persistent volume
# ✅ CRITICAL UPDATE: Swapped large SAFETENSORS for smaller GGUF models to fix "Cannot allocate memory" error

# --- 0: Set Working Directory for Persistence ---
# RunPod typically mounts persistent storage to /workspace. 
# We'll install everything here to ensure it survives reboots.
COMFYUI_DIR="/workspace/ComfyUI"

echo "--- Setting ComfyUI installation directory to: $COMFYUI_DIR ---"

# --- 1: Check OS (Optional, but good practice) ---
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "This script is designed for Linux. Exiting."
    exit 1
fi

# --- 2: Install System Dependencies ---
# Note: Use a clean environment variable for apt-get to avoid conflicts
echo "--- Installing system dependencies ---"
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y
apt install -y git python3 python3-venv python3-pip curl libgl1-mesa-glx libsndfile1 unzip ffmpeg

# --- 3: Clone ComfyUI ---
cd /workspace
rm -rf "$COMFYUI_DIR"
git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
cd "$COMFYUI_DIR"

# Python environment
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# --- 4: Create standard model folders ---
mkdir -p models/checkpoints models/vae models/clip models/audio models/text_encoders \
         models/loras models/clip_vision models/multitalk models/video models/diffusion_models

# --- 5: Clone Custom Nodes ---
echo "--- Installing custom nodes ---"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
rm -rf "$CUSTOM_NODES_DIR"
mkdir -p "$CUSTOM_NODES_DIR"
cd "$CUSTOM_NODES_DIR"

# ✅ FIXED: Updated ComfyUI-Manager repository location
git clone https://github.com/Comfy-Org/ComfyUI-Manager.git
git clone --branch comfyui https://github.com/MeiGen-AI/InfiniteTalk.git
git clone https://github.com/kijai/ComfyUI-KJNodes.git
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git
git clone https://github.com/rgthree/rgthree-comfy.git
git clone https://github.com/christian-byrne/audio-separation-nodes-comfyui.git
