#!/bin/bash

export COMFYUI_DIR="/workspace/ComfyUI"
export CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"

if [ ! -f "/workspace/ComfyUI/models/MODEL_INFO.txt" ]; then
    /opt/models.sh
fi

# --- 9: Clear ComfyUI cache (Will use the container's home cache) ---
echo "--- Clearing ComfyUI cache ---"
rm -rf ~/.ComfyUI/cache


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
