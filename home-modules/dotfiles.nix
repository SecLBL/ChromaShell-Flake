inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg  = config.programs.chromashell;
  dots = "${inputs.dotfiles}/dots/.config";

  editorCmds = {
    vscodium = "codium";
    vscode   = "code";
    zed      = "zeditor";
    micro    = "kitty -e micro";
    helix    = "kitty -e hx";
    neovim   = "kitty -e nvim";
  };

  browserCmds = {
    firefox   = "firefox";
    librewolf = "librewolf";
    zen       = "zen";
    brave     = "brave";
    chromium  = "chromium";
  };
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

      # ── ChromaShell runtime directory ──────────────────────────────────
      # Individual file entries so HM creates audio/ and theming/ as real
      # directories (not store symlinks), allowing runtime/ subdirs inside.
      "chromashell/audio/start-jalv.sh"      = { source = "${dots}/chromashell/audio/start-jalv.sh";      executable = true; };
      "chromashell/audio/audio-param.sh"    = { source = "${dots}/chromashell/audio/audio-param.sh";    executable = true; };
      "chromashell/audio/audio-route.sh"    = { source = "${dots}/chromashell/audio/audio-route.sh";    executable = true; };
      "chromashell/audio/audio-nr-bypass.sh"= { source = "${dots}/chromashell/audio/audio-nr-bypass.sh";executable = true; };
      "chromashell/audio/volume-control.sh" = { source = "${dots}/chromashell/audio/volume-control.sh"; executable = true; };
      "chromashell/audio/audio.json.default".source = "${dots}/chromashell/audio/audio.json.default";
      "chromashell/theming/posthook.sh"    = { source = "${dots}/chromashell/theming/posthook.sh"; executable = true; };
      "chromashell/theming/sse-server.py".source = "${dots}/chromashell/theming/sse-server.py";

      # ── Pipewire virtual nodes ──────────────────────────────────────────
      "pipewire/pipewire.conf.d/loopback.conf".source                  = "${dots}/pipewire/pipewire.conf.d/loopback.conf";
      "pipewire/pipewire.conf.d/filter-chain-general-in.conf".source  = "${dots}/pipewire/pipewire.conf.d/filter-chain-general-in.conf";
      "pipewire/pipewire.conf.d/filter-chain-general-out.conf".source = "${dots}/pipewire/pipewire.conf.d/filter-chain-general-out.conf";
      "pipewire/pipewire.conf.d/filter-chain-mic-in.conf".source      = "${dots}/pipewire/pipewire.conf.d/filter-chain-mic-in.conf";
      "pipewire/pipewire.conf.d/filter-chain-mic-out.conf".source     = "${dots}/pipewire/pipewire.conf.d/filter-chain-mic-out.conf";
      "pipewire/pipewire.conf.d/filter-chain-chat-in.conf".source     = "${dots}/pipewire/pipewire.conf.d/filter-chain-chat-in.conf";
      "pipewire/pipewire.conf.d/filter-chain-chat-out.conf".source    = "${dots}/pipewire/pipewire.conf.d/filter-chain-chat-out.conf";

      # ── Kitty ──────────────────────────────────────────────────────────
      "kitty".source = "${dots}/kitty";

      # ── Spicetify (user.css only — color.ini written at runtime by caelestia-cli) ──
      "spicetify/Themes/caelestia/user.css".source = "${dots}/spicetify/Themes/caelestia/user.css";

      # ── Btop (conf only — themes/ stays writable for caelestia-cli) ────
      "btop/btop.conf".source = "${dots}/btop/btop.conf";

      # ── Fastfetch ───────────────────────────────────────────────────────
      "fastfetch/config.jsonc".source = "${dots}/fastfetch/config.jsonc";

      # ── Fish ───────────────────────────────────────────────────────────
      "fish/config.fish".source   = "${dots}/fish/config.fish";
      "fish/functions".source     = "${dots}/fish/functions";

      # ── Starship ───────────────────────────────────────────────────────
      "starship.toml".source = "${dots}/starship.toml";

      # ── Thunar ─────────────────────────────────────────────────────────
      "Thunar".source = "${dots}/Thunar";

      # ── Editor configs (deployed when editor.app is set) ────────────────
      "VSCodium/User/settings.json"    = mkIf (cfg.editor.app == "vscodium") { source = "${dots}/vscode/User/settings.json"; };
      "VSCodium/User/keybindings.json" = mkIf (cfg.editor.app == "vscodium") { source = "${dots}/vscode/User/keybindings.json"; };
      "codium-flags.conf"              = mkIf (cfg.editor.app == "vscodium") { source = "${dots}/vscode/flags.conf"; };
      "Code/User/settings.json"        = mkIf (cfg.editor.app == "vscode")   { source = "${dots}/vscode/User/settings.json"; };
      "Code/User/keybindings.json"     = mkIf (cfg.editor.app == "vscode")   { source = "${dots}/vscode/User/keybindings.json"; };
      "code-flags.conf"                = mkIf (cfg.editor.app == "vscode")   { source = "${dots}/vscode/flags.conf"; };
      "zed/settings.json"              = mkIf (cfg.editor.app == "zed")      { source = "${dots}/zed/settings.json"; };
      "zed/keymap.json"                = mkIf (cfg.editor.app == "zed")      { source = "${dots}/zed/keymap.json"; };
      "micro/settings.json"            = mkIf (cfg.editor.app == "micro")    { source = "${dots}/micro/settings.json"; };

      # ── Hyprland generated overrides (flake-managed, written to hypr/generated/) ─
      # Not in custom/ — that directory is user-managed and never overwritten by the flake.
      # When app = null the file simply doesn't exist; pcall handles the missing module.
      "hypr/generated/editor.lua"  = mkIf (cfg.editor.app != null) {
        text = "require(\"config.variables\").editor = \"${editorCmds.${cfg.editor.app}}\"";
      };
      "hypr/generated/browser.lua" = mkIf (cfg.browser.app != null) {
        text = "require(\"config.variables\").browser = \"${browserCmds.${cfg.browser.app}}\"";
      };

      # ── uwsm session environment ────────────────────────────────────────
      "uwsm/env".source          = "${dots}/uwsm/env";
      "uwsm/env-hyprland".source = "${dots}/uwsm/env-hyprland";
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

      mkdir -p "$HOME/.config/chromashell/audio/runtime"
      mkdir -p "$HOME/.config/chromashell/theming/runtime"

      # Per-machine Hyprland config (monitors, workspaces)
      create_stub "$HOME/.config/hypr/monitors.lua" \
        "-- Monitor layout — edit for your machine
-- hl.monitor({ output=\"DP-1\", mode=\"2560x1440@144\", position=\"0x0\", scale=1 })
hl.monitor({ output=\"\", mode=\"preferred\", position=\"auto\", scale=1 })"

      create_stub "$HOME/.config/hypr/workspaces.lua" \
        "-- Workspace rules — edit for your machine.
-- Each monitor must own exactly 10 contiguous workspaces starting at a multiple of 10 + 1.
-- This is required for wsaction.fish: floor((active_ws - 1) / 10) * 10 + slot
--
-- 2-monitor example:
--   hl.workspace_rule({ workspace=\"1\",  monitor=\"DP-1\", default=true })
--   ...
--   hl.workspace_rule({ workspace=\"10\", monitor=\"DP-1\" })
--   hl.workspace_rule({ workspace=\"11\", monitor=\"DP-2\", default=true })
--   ...
--   hl.workspace_rule({ workspace=\"20\", monitor=\"DP-2\" })
--
-- 3-monitor example: add workspaces 21-30 for the third monitor.
-- Run: hyprctl monitors | grep Monitor   to find output names."

      # User custom overrides
      create_stub "$HOME/.config/hypr/custom/env.lua"         "-- Custom env vars"
      create_stub "$HOME/.config/hypr/custom/rules.lua"       "-- Custom window rules"
      create_stub "$HOME/.config/hypr/custom/keybindings.lua" "-- Custom keybindings"
      create_stub "$HOME/.config/hypr/custom/autostart.lua"   "-- Custom autostart"
      create_stub "$HOME/.config/hypr/custom/variables.lua"   "-- Custom variable overrides (loaded before keybindings)\n-- local v = require(\"config.variables\"); v.terminal = \"wezterm\""
      create_stub "$HOME/.config/hypr/custom/settings.lua"    "-- Custom settings (hl.config calls merge with existing values)\n-- hl.config({ decoration = { rounding = 10 } })"
    '';
  };
}
