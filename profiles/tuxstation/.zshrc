source ~/.zshrc-common

## Tuxstation ##

alias comfyui="cd ~/ComfyUI && source venv/bin/activate && python main.py"

# Sunshine (Moonlight host) — user service
alias sun-status="systemctl --user status app-dev.lizardbyte.app.Sunshine.service"
alias sun-restart="systemctl --user restart app-dev.lizardbyte.app.Sunshine.service"
alias sun-start="systemctl --user start app-dev.lizardbyte.app.Sunshine.service"
alias sun-stop="systemctl --user stop app-dev.lizardbyte.app.Sunshine.service"
alias sun-logs="journalctl --user -u app-dev.lizardbyte.app.Sunshine.service -f"

# IVPN — split-tunnel config keeps Tailscale/SSH reachable while connected
alias vpn="ivpn status"
alias vpn-on="ivpn connect -any -city Chicago"
alias vpn-fast="ivpn connect -fastest"
alias vpn-off="ivpn disconnect"

# upscale a video: no args = interactive wizard; or upscale <src> <out.mp4>. env knobs compose; upscale-help
upscale()         { if [ $# -eq 0 ]; then "$HOME/tools/upscale-wizard.sh"; else "$HOME/tools/vsupscale.sh" "$@"; fi; }
# fast 2-frame QC preview .png (no full render) — dial settings quickly
upscale-preview() { SHEET_ONLY=1 "$HOME/tools/vsupscale.sh" "$@"; }
# render at 1080p instead of 4K
upscale-1080()    { P=1080 "$HOME/tools/vsupscale.sh" "$@"; }
# non-anime model (realesrgan-x4plus), max fidelity (~2x slower)
upscale-hq()      { ESRGAN_MODEL=realesrgan-x4plus "$HOME/tools/vsupscale.sh" "$@"; }
# fastest: nvenc final encode
upscale-fast()    { ENC=nvenc "$HOME/tools/vsupscale.sh" "$@"; }
# use RealCUGAN instead of Real-ESRGAN for the blend pass (detail-preserving alt)
upscale-cugan()   { BLEND_ENGINE=cugan "$HOME/tools/vsupscale.sh" "$@"; }
# print all upscale commands + env knobs
upscale-help() {
  cat <<'EOF'
vsupscale — 480p+/DVD/VOB -> 4K (or 1080p). Preserves source aspect ratio; audio copied (lossless).
Prefix any command with env knobs, e.g.:  DENOISE=2 DEBLOCK=strong ENC=nvenc upscale in.vob out.mp4

  Commands
    upscale                            no args -> interactive wizard (fzf file picker + menus)
    upscale <src> <out.mp4>            full render + QC sheet (<out>.compare.png)
    upscale-preview <src> <out.png>    fast 2-frame QC sheet only (dial settings quickly)
    upscale-1080 <src> <out.mp4>       1080p instead of 4K
    upscale-hq <src> <out.mp4>         non-anime model, max fidelity (~2x slower)
    upscale-fast <src> <out.mp4>       nvenc final encode (fastest)
    upscale-cugan <src> <out.mp4>      RealCUGAN blend engine (detail-preserving alt)

  Cleanup / detail
    DENOISE       0 off (default) | 1-3 light | 4-8 stronger      znedi3 BM3D denoise
    DEBLOCK       none (default) | weak | strong                  DVD/mpeg block-edge removal
    SHARP         0.8 default | ~0.5 moderate | 0 off             unsharp detail
    ESRGAN        0.35 default (blend fraction) | 0 = pure znedi3 esrgan edge-character mix
    ESRGAN_SHARP  0.5 default | 0 off                             cas sharpen on esrgan pass

  Model / speed
    ESRGAN_MODEL  realesr-animevideov3 (fast, default) | realesrgan-x4plus (max fidelity)
    BLEND_ENGINE  esrgan (default) | cugan                        RealCUGAN detail-preserving alt
    CUGAN_NOISE   -1 conservative (default) | 0 none | 3 clean    cugan denoise level
    ESRGAN_JOBS   3:12:3 default                                  esrgan/cugan load:proc:save threads
    ENC           x264 quality (default) | nvenc | h264_nvenc     final encoder

  Size / scope
    P             2160 (default) | 1080                           target height (AR preserved)
    TW / TH       explicit target size (override P)
    SECS          process only the first N seconds
    COMPARE       1 write QC sheet (default) | 0 skip
    SHEET_ONLY    1 = only the 2-frame QC png (what upscale-preview sets)

  Output: <name>.<timestamp>.mp4 (+ .compare.png). Use a .mkv output to keep audio as-is (no ALAC).
EOF
}

purrfetch
