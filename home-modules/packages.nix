inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;
  qsPkg = inputs.quickshell.packages.${pkgs.system}.default;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Shell
      qsPkg
      matugen
      swww

      # Hyprland utilities
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

      # Audio
      pamixer
      pulseaudio

      # System info
      inotify-tools
      jq
      socat
      bc
      lm_sensors

      # Fonts
      (nerdfonts.override { fonts = [ "JetBrainsMono" "Iosevka" ]; })
    ];
  };
}
