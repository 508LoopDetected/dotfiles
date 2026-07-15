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

purrfetch
