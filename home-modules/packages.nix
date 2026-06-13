inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # ── Shell runtime ────────────────────────
      kitty
      fish
      starship

      # ── Hyprland utilities ───────────────────
      hyprlock
      hypridle
      hyprpicker
      wl-clipboard
      cliphist
      ydotool
      grim
      swappy

      # ── Screen recording ─────────────────────
      gpu-screen-recorder

      # ── Audio ────────────────────────────────
      jalv
      pipewire.jack   # pw-jack wrapper — routes jalv through PipeWire JACK compat
      lsp-plugins
      rnnoise-plugin
      noise-repellent
      pamixer
      pulseaudio      # wpctl / pactl
      pavucontrol
      mpv             # shell.json general.apps.playback default (recording playback)

      # ── File manager ─────────────────────────
      thunar

      # ── Theming ──────────────────────────────
      adw-gtk3
      papirus-icon-theme
      pywal

      # ── Caelestia spawn support ──────────────
      app2unit

      # ── System monitoring ────────────────────
      btop
      ddcutil
      fastfetch
      eza

      # ── System / scripting ───────────────────
      inotify-tools
      jq
      socat
      bc
      imagemagick
      curl

      # ── Fonts ────────────────────────────────
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      material-symbols
    ];
  };
}
