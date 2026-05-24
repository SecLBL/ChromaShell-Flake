inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg  = config.programs.chromashell;
  dots = "${inputs.dotfiles}/dots/.config";
in
{
  config = mkIf cfg.enable {

    xdg.configFile = {

      # ── Hyprland ───────────────────────────────────────────────────────
      "hypr/hyprland.lua".source = "${dots}/hypr/hyprland.lua";
      "hypr/config".source           = "${dots}/hypr/config";
      "hypr/scripts".source = pkgs.runCommand "chromashell-hypr-scripts" {} ''
        cp -r ${dots}/hypr/scripts $out
        chmod -R +x $out
      '';

      # ── Pipewire virtual nodes ──────────────────────────────────────────
      "pipewire/pipewire.conf.d/loopback.conf".source       = "${dots}/pipewire/pipewire.conf.d/loopback.conf";
      "pipewire/pipewire.conf.d/filter-chain-mic.conf".source  = "${dots}/pipewire/pipewire.conf.d/filter-chain-mic.conf";
      "pipewire/pipewire.conf.d/filter-chain-chat.conf".source = "${dots}/pipewire/pipewire.conf.d/filter-chain-chat.conf";

      # ── Kitty ──────────────────────────────────────────────────────────
      "kitty".source = "${dots}/kitty";

      # ── Fish ───────────────────────────────────────────────────────────
      "fish/conf.d/chromashell.fish".source = "${dots}/fish/conf.d/chromashell.fish";

      # ── Starship ───────────────────────────────────────────────────────
      "starship.toml".source = "${dots}/starship.toml";
    };

    # Writable per-machine files — created once, never overwritten by home-manager
    home.activation.chromashellWritableStubs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      create_stub() {
        local file="$1"
        local content="$2"
        if [ ! -f "$file" ]; then
          mkdir -p "$(dirname "$file")"
          printf '%s\n' "$content" > "$file"
        fi
      }

      # Per-machine Hyprland config (monitors, workspaces)
      create_stub "$HOME/.config/hypr/monitors.lua" \
        "-- Monitor layout — edit for your machine
-- hl.monitor({ output=\"DP-1\", mode=\"2560x1440@144\", position=\"0x0\", scale=1 })
hl.monitor({ output=\"\", mode=\"preferred\", position=\"auto\", scale=1 })"

      create_stub "$HOME/.config/hypr/workspaces.lua" \
        "-- Workspace rules — edit for your machine
-- hl.workspace_rule({ workspace=\"1\", monitor=\"DP-1\", default=true })"

      # User custom overrides
      create_stub "$HOME/.config/hypr/custom/env.lua"         "-- Custom env vars"
      create_stub "$HOME/.config/hypr/custom/rules.lua"       "-- Custom window rules"
      create_stub "$HOME/.config/hypr/custom/keybindings.lua" "-- Custom keybindings"
      create_stub "$HOME/.config/hypr/custom/autostart.lua"   "-- Custom autostart"
    '';
  };
}
