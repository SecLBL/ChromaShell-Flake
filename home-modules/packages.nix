inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg  = config.programs.chromashell;
  qsPkg = inputs.quickshell.packages.${pkgs.system}.default;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # ── Shell ────────────────────────────────
      qsPkg
      matugen
      swww

      # ── Hyprland utilities ───────────────────
      rofi-wayland
      swayosd
      hyprlock
      hypridle
      wl-clipboard
      cliphist
      grim
      slurp
      satty
      playerctl

      # ── Audio ────────────────────────────────
      jalv
      lsp-plugins
      rnnoise-plugin
      noise-repellent
      pamixer
      pulseaudio      # wpctl / pactl

      # ── Theming ──────────────────────────────
      pywal           # pywal backend
      adw-gtk3

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
    ];
  };
}
