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
      lsp-plugins
      rnnoise-plugin
      noise-repellent
      pamixer
      pulseaudio      # wpctl / pactl
      pavucontrol

      # ── File manager ─────────────────────────
      thunar

      # ── Theming ──────────────────────────────
      adw-gtk3
      papirus-icon-theme

      # ── Caelestia spawn support ──────────────
      app2unit

      # ── System monitoring ────────────────────
      btop
      ddcutil
      fastfetch

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
