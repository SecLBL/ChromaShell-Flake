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

      # ── Quickshell ─────────────────────────────────────────────────────
      "quickshell".source = pkgs.runCommand "chromashell-qs-patched" {
        buildInputs = [ pkgs.bash ];
      } ''
        cp -r ${dots}/quickshell $out
        chmod -R +w $out
        patchShebangs $out
      '';

      # ── Hyprland ───────────────────────────────────────────────────────
      "hypr/chromashell.conf".source = "${dots}/hypr/hyprland.conf";
      "hypr/config".source           = "${dots}/hypr/config";
      "hypr/scripts".source          = "${dots}/hypr/scripts";

      # ── Matugen ────────────────────────────────────────────────────────
      "matugen".source = "${dots}/matugen";

      # ── Pipewire virtual nodes ──────────────────────────────────────────
      "pipewire/pipewire.conf.d/loopback.conf".source       = "${dots}/pipewire/pipewire.conf.d/loopback.conf";
      "pipewire/pipewire.conf.d/filter-chain-mic.conf".source  = "${dots}/pipewire/pipewire.conf.d/filter-chain-mic.conf";
      "pipewire/pipewire.conf.d/filter-chain-chat.conf".source = "${dots}/pipewire/pipewire.conf.d/filter-chain-chat.conf";

      # ── Kitty ──────────────────────────────────────────────────────────
      "kitty".source = "${dots}/kitty";

      # ── Pywal templates ────────────────────────────────────────────────
      "wal/templates".source = "${dots}/wal/templates";

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
      create_stub "$HOME/.config/hypr/monitors.conf" \
        "# Monitor layout — edit for your machine
# monitor = name, resolution@hz, position, scale
# monitor = DP-1, 2560x1440@144, 0x0, 1
monitor = , preferred, auto, 1"

      create_stub "$HOME/.config/hypr/workspaces.conf" \
        "# Workspace rules — edit for your machine
# workspace = 1, monitor:DP-1, default:true"

      # User custom overrides
      create_stub "$HOME/.config/hypr/custom/env.conf"        "# Custom env vars"
      create_stub "$HOME/.config/hypr/custom/rules.conf"      "# Custom window rules"
      create_stub "$HOME/.config/hypr/custom/keybindings.conf" "# Custom keybindings"
      create_stub "$HOME/.config/hypr/custom/autostart.conf"  "# Custom autostart"
    '';
  };
}
