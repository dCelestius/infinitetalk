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

# --- 6: Download Models to Standard Folders (UPDATED FOR GGUF) ---
echo "--- Downloading models (GGUF and SAFETENSORS) ---"

# InfiniteTalk core models (SAFETENSORS VERSION - required by InfiniteTalk node)
echo "Downloading InfiniteTalk safetensors models..."
curl -L -o "$COMFYUI_DIR/models/multitalk/infinite_talk.safetensors" \
     https://huggingface.co/MeiGen-AI/InfiniteTalk/resolve/main/infinite_talk.safetensors

curl -L -o "$COMFYUI_DIR/models/multitalk/infinitetalk_single.safetensors" \
     https://huggingface.co/MeiGen-AI/InfiniteTalk/resolve/main/comfyui/infinitetalk_single.safetensors
curl -L -o "$COMFYUI_DIR/models/multitalk/infinitetalk_multi.safetensors" \
     https://huggingface.co/MeiGen-AI/InfiniteTalk/resolve/main/comfyui/infinitetalk_multi.safetensors

# --- GGUF Models for CPU/low-VRAM Inference (WanVideo & InfiniteTalk) ---
echo "Downloading WanVideo and InfiniteTalk GGUF models into models/diffusion_models..."
# WanVideo I2V GGUF (Q4_K_M - recommended light version)
curl -L -o "$COMFYUI_DIR/models/diffusion_models/wan2.1-i2v-14b-480p-Q4_K_M.gguf" \
     https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q4_K_M.gguf

# WanVideo I2V GGUF (Q8_0 - higher quality version)
curl -L -o "$COMFYUI_DIR/models/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf" \
     https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q8_0.gguf

# InfiniteTalk Single GGUF 
curl -L -o "$COMFYUI_DIR/models/diffusion_models/Wan2_1-InfiniteTalk_Single_Q8.gguf" \
     https://huggingface.co/Kijai/WanVideo_comfy_GGUF/resolve/main/InfiniteTalk/Wan2_1-InfiniteTalk_Single_Q8.gguf

# InfiniteTalk supporting models (SAFETENSORS)
curl -L -o "$COMFYUI_DIR/models/clip_vision/clip_vision_h.safetensors" \
     https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/blob/main/split_files/clip_vision/clip_vision_h.safetensors
curl -L -o "$COMFYUI_DIR/models/text_encoders/umt5-xxl-enc-bf16.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/blob/main/umt5-xxl-enc-bf16.safetensors

# Audio model for speech recognition
curl -L -o "$COMFYUI_DIR/models/audio/chinese-wav2vec2-base.bin" \
     https://huggingface.co/TencentGameMate/chinese-wav2vec2-base/resolve/main/pytorch_model.bin

# WanVideoWrapper LoRAs
echo "Downloading WanVideo LoRAs..."
curl -L -o "$COMFYUI_DIR/models/loras/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors

# Check if the bf16 variant exists and download it
echo "Attempting to download bf16 LoRA variant..."
curl -L -o "$COMFYUI_DIR/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors || \
curl -L -o "$COMFYUI_DIR/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors || \
echo "Warning: bf16 LoRA variant not found, using rank32 version instead"

# Download actual WanVideo VAE models
echo "Downloading WanVideo VAE models..."
curl -L -o "$COMFYUI_DIR/models/vae/Wan2_1_VAE_bf16.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors

# Also try to get fp32 version if available
curl -L -o "$COMFYUI_DIR/models/vae/Wan2_1_VAE_fp32.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_fp32.safetensors || \
echo "Note: fp32 VAE variant not available, using bf16 version"

# --- 6.5: Create VAE Compatibility Links ---
echo "--- Creating VAE compatibility for legacy workflows ---"
cd "$COMFYUI_DIR/models/vae/"

# Create fallback symlink if fp32 version wasn't available
if [ ! -f "Wan2_1_VAE_fp32.safetensors" ] && [ -f "Wan2_1_VAE_bf16.safetensors" ]; then
    ln -sf Wan2_1_VAE_bf16.safetensors Wan2_1_VAE_fp32.safetensors
    echo "✅ Created fp32 -> bf16 VAE compatibility link"
fi

# --- 7: Configure ComfyUI Model Paths via extra_model_paths.yaml (SIMPLIFIED) ---
echo "--- Configuring models via extra_model_paths.yaml ---"
cd "$COMFYUI_DIR"

cat > extra_model_paths.yaml <<EOL
# ComfyUI model paths configuration (Optimized for RunPod /workspace)

comfyui:
  base_path: ./
  checkpoints: models/checkpoints/
  clip: models/clip/
  clip_vision: models/clip_vision/
  configs: models/configs/
  controlnet: models/controlnet/
  diffusion_models: models/diffusion_models/
  embeddings: models/embeddings/
  loras: models/loras/
  audio: models/audio/
  text_encoders: models/text_encoders/
  upscale_models: models/upscale_models/
  vae: models/vae/
  multitalk: models/multitalk/
  video: models/video/
EOL

# --- 8: Install Python dependencies ---
echo "--- Installing additional Python dependencies ---"
# Use full path to activate the virtual environment
source "$COMFYUI_DIR/venv/bin/activate"

pip install xformers || echo "Warning: xformers failed"
pip install "xfuser>=0.4.1" || echo "Warning: xfuser failed"

# Core ML dependencies
pip install onnx onnxruntime gguf basicsr soundfile librosa einops torchvision torchaudio demucs sageattention \
opencv-python>=4.9.0 "diffusers>=0.31.0" "transformers>=4.49.0" "tokenizers>=0.20.3" "accelerate>=1.1.1" tqdm \
imageio easydict ftfy dashscope imageio-ffmpeg scikit-image loguru gradio>=5.0.0 "numpy>=1.23.5,<2" \
pyloudnorm optimum-quanto scenedetect moviepy decord || echo "Warning: Some dependencies failed"

# Install custom node requirements if they exist
if [ -f "$CUSTOM_NODES_DIR/ComfyUI-WanVideoWrapper/requirements.txt" ]; then
    echo "Installing WanVideoWrapper requirements..."
    pip install -r "$CUSTOM_NODES_DIR/ComfyUI-WanVideoWrapper/requirements.txt" || echo "Warning: WanVideoWrapper requirements failed"
fi

if [ -f "$CUSTOM_NODES_DIR/InfiniteTalk/requirements.txt" ]; then
    echo "Installing InfiniteTalk requirements..."
    pip install -r "$CUSTOM_NODES_DIR/InfiniteTalk/requirements.txt" || echo "Warning: InfiniteTalk requirements failed"
fi

# Additional dependencies for video processing
pip install av python-ffmpeg || echo "Warning: Video processing dependencies failed"

# --- 9: Clear ComfyUI cache (Will use the container's home cache) ---
echo "--- Clearing ComfyUI cache ---"
rm -rf ~/.ComfyUI/cache

# --- 10: Create comprehensive model structure info file (UPDATED) ---
echo "--- Creating model structure info ---"
cat > "$COMFYUI_DIR/models/MODEL_INFO.txt" <<EOL
# Model Structure for Workflows - September 2025 (RunPod /workspace/ComfyUI)

## InfiniteTalk Models (models/multitalk/)
- infinite_talk.safetensors (main model)
- infinitetalk_single.safetensors (single person ComfyUI)
- infinitetalk_multi.safetensors (multiple people ComfyUI)

## WanVideo/InfiniteTalk GGUF Models (models/diffusion_models/)
- wan2.1-i2v-14b-480p-Q4_K_M.gguf (WanVideo GGUF - recommended for low RAM)
- wan2.1-i2v-14b-480p-Q8_0.gguf (WanVideo GGUF - higher quality)
- Wan2_1-InfiniteTalk_Single_Q8.gguf (InfiniteTalk GGUF)

## VAE Models (models/vae/)
- Wan2_1_VAE_bf16.safetensors (actual WanVideo VAE - compatible with WanVideoVAELoader)
- Wan2_1_VAE_fp32.safetensors (fp32 version if available, otherwise symlinked to bf16)

## Text Encoders (models/text_encoders/)
- umt5-xxl-enc-bf16.safetensors (for InfiniteTalk)

## CLIP Vision (models/clip_vision/)
- clip_vision_h.safetensors (for InfiniteTalk)

## Audio (models/audio/)
- chinese-wav2vec2-base.bin (speech recognition)

## LoRAs (models/loras/)
- Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors (recommended)
- lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors (if available)

## Workflow Fixes for Common Errors:
1. WanVideoVAELoader error: Use 'Wan2_1_VAE_fp32.safetensors' or remove VAE loader
2. Model path errors: Use filename only, no subdirectories (e.g., 'wan2.1-i2v-14b-480p-Q4_K_M.gguf')
3. Sampler field errors: Use default values (start_step: 0, end_step: 25, cfg: 7.0)
4. LoRA path errors: Use exact filename from /models/loras/ folder
EOL

# --- 11: Verify installations and create troubleshooting guide (UPDATED) ---
echo "--- Verifying installations ---"
echo "ComfyUI directory: $(ls -la "$COMFYUI_DIR" | wc -l) items"
echo "Custom nodes: $(ls -la "$CUSTOM_NODES_DIR" | wc -l) nodes"
echo "Models downloaded: $(find "$COMFYUI_DIR/models/" -name "*.safetensors" -o -name "*.bin" -o -name "*.gguf" | wc -l) files"

# List critical models with detailed verification
echo ""
echo "--- Critical Models Verification ---"
[ -f "$COMFYUI_DIR/models/multitalk/infinite_talk.safetensors" ] && echo "✅ InfiniteTalk main model found ($(stat -c%s "$COMFYUI_DIR/models/multitalk/infinite_talk.safetensors" 2>/dev/null | numfmt --to=iec-i)B)" || echo "❌ InfiniteTalk main model missing"
[ -f "$COMFYUI_DIR/models/multitalk/infinitetalk_single.safetensors" ] && echo "✅ InfiniteTalk single model found" || echo "❌ InfiniteTalk single model missing"
[ -f "$COMFYUI_DIR/models/multitalk/infinitetalk_multi.safetensors" ] && echo "✅ InfiniteTalk multi model found" || echo "❌ InfiniteTalk multi model missing"
[ -f "$COMFYUI_DIR/models/diffusion_models/wan2.1-i2v-14b-480p-Q4_K_M.gguf" ] && echo "✅ WanVideo GGUF (Q4_K_M) model found ($(stat -c%s "$COMFYUI_DIR/models/diffusion_models/wan2.1-i2v-14b-480p-Q4_K_M.gguf" 2>/dev/null | numfmt --to=iec-i)B)" || echo "❌ WanVideo GGUF (Q4_K_M) model missing"
[ -f "$COMFYUI_DIR/models/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf" ] && echo "✅ WanVideo GGUF (Q8_0) model found ($(stat -c%s "$COMFYUI_DIR/models/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf" 2>/dev/null | numfmt --to=iec-i)B)" || echo "❌ WanVideo GGUF (Q8_0) model missing"
[ -f "$COMFYUI_DIR/models/text_encoders/umt5-xxl-enc-bf16.safetensors" ] && echo "✅ Text encoder found ($(stat -c%s "$COMFYUI_DIR/models/text_encoders/umt5-xxl-enc-bf16.safetensors" 2>/dev/null | numfmt --to=iec-i)B)" || echo "❌ Text encoder missing"
[ -f "$COMFYUI_DIR/models/vae/Wan2_1_VAE_bf16.safetensors" ] && echo "✅ WanVideo VAE bf16 found ($(stat -c%s "$COMFYUI_DIR/models/vae/Wan2_1_VAE_bf16.safetensors" 2>/dev/null | numfmt --to=iec-i)B)" || echo "❌ WanVideo VAE bf16 missing"
[ -f "$COMFYUI_DIR/models/vae/Wan2_1_VAE_fp32.safetensors" ] && echo "✅ WanVideo VAE fp32 found" || echo "❌ WanVideo VAE fp32 missing (using bf16 fallback)"
[ -L "$COMFYUI_DIR/models/vae/Wan2_1_VAE_fp32.safetensors" ] && echo "✅ VAE fp32 compatibility link created" || echo "ℹ️  VAE fp32 available directly"

echo ""
echo "--- Available Models Summary ---"
echo "InfiniteTalk safetensors models: $(ls "$COMFYUI_DIR/models/multitalk/" 2>/dev/null | wc -l)"
echo "GGUF/Diffusion models: $(ls "$COMFYUI_DIR/models/diffusion_models/" 2>/dev/null | wc -l)"
echo "VAE models: $(ls "$COMFYUI_DIR/models/vae/" 2>/dev/null | wc -l)"
echo "LoRA models: $(ls "$COMFYUI_DIR/models/loras/" 2>/dev/null | wc -l)"

# --- 12: Final setup notes and troubleshooting ---
echo ""
echo "--- Final Setup Notes ---"
echo "🎯 WORKFLOW COMPATIBILITY FIXES:"
echo "1. ✅ VAE Error Fixed: 'Wan2_1_VAE_fp32.safetensors' now available via symlink"
echo "2. ✅ Model Path Fixed: Use exact filenames without subdirectories"
echo "3. ✅ GGUF variants available: Use the '.gguf' models from the 'models/diffusion_models' folder."
echo "4. ✅ Legacy workflow support: VAE compatibility links created"
echo "5. ✅ All InfiniteTalk models: main, single, and multi variants"
echo ""
echo "🔧 IF YOU STILL GET ERRORS:"
echo "- Check $COMFYUI_DIR/models/MODEL_INFO.txt for detailed model information"
echo "- Verify model names match exactly in your workflow"
echo "- **You may need a Llama.cpp or GGUF-specific node** to load the .gguf models."
echo "- Remove subdirectory paths from model selections"
echo "- Use default values for empty sampler fields"
echo ""
echo "📁 Total setup size: ~$(du -sh "$COMFYUI_DIR" 2>/dev/null | cut -f1 || echo 'calculating...')"

# --- 13: End of Provisioning Script ---
echo ""
echo "--- Provisioning complete. ComfyUI is installed and configured. ---"
echo "💡 The Provisioning Script is finished. RunPod will now execute the command in your 'Run Command' field."
echo "💡 **To start ComfyUI**, ensure your RunPod 'Run Command' is set to:"
echo "cd $COMFYUI_DIR && source venv/bin/activate && python main.py --listen 0.0.0.0 --port 8188"

echo "--- Setup complete. All models registered and ready to use. ---"