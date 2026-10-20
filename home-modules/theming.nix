inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkDefault;
  cfg = config.programs.chromashell;
in
{
  config = mkIf cfg.enable {
    gtk = {
      enable = true;
      theme  = {
        name    = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name    = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk4.theme = null;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    # hypr/config/variables.lua expects Bibata-Modern-Classic (size 18); without
    # the theme installed Hyprland falls back to a 1px cursor
    home.pointerCursor = mkDefault {
      name    = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size    = 18;
      gtk.enable        = true;
      x11.enable        = true;
      hyprcursor.enable = true;
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk";
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme    = "adw-gtk3-dark";
      };
    };
  };
}
