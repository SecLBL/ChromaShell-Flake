inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;
  quickshell = pkgs.quickshell.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ pkgs.qt6.qtmultimedia ];
  });
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # ── Shell ────────────────────────────────
      quickshell
      matugen
      awww
      kitty
      fish
      starship

      # ── Hyprland utilities ───────────────────
      rofi
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
      material-symbols
    ];
  };
}
