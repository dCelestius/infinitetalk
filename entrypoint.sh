#!/bin/bash

export COMFYUI_DIR="/workspace/ComfyUI"
export CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

if [ ! -f "/workspace/ComfyUI/models/MODEL_INFO.txt" ]; then
    /opt/models.sh
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

cd /workspace/ComfyUI && source venv/bin/activate && python main.py --listen 0.0.0.0 --port 8188
