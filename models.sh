#!/bin/bash


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
     https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors
curl -L -o "$COMFYUI_DIR/models/text_encoders/umt5-xxl-enc-bf16.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/blob/main/umt5-xxl-enc-bf16.safetensors

# Audio model for speech recognition
curl -L -o "$COMFYUI_DIR/models/audio/chinese-wav2vec2-base.bin" \
     https://huggingface.co/TencentGameMate/chinese-wav2vec2-base/resolve/main/pytorch_model.bin

# WanVideoWrapper LoRAs
echo "Downloading WanVideo LoRAs..."
curl -L -o "$COMFYUI_DIR/models/loras/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors

# Text Encoders
echo "Downloading text encoders..."
curl -L -o "$COMFYUI_DIR/models/text_encoders/umt5-xxl-enc-fp8_e4m3fn.safetensors" \
     https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-fp8_e4m3fn.safetensors

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
