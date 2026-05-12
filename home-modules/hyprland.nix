inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;
  dotfilesSource = inputs.dotfiles;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      xwayland.enable = true;
      extraConfig = ''
        source = ${config.xdg.configHome}/hypr/chromashell.conf
      '';
    };
  };
}
