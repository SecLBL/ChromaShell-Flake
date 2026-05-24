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
      awww            # wallpaper daemon (used by caelestia-cli)
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
