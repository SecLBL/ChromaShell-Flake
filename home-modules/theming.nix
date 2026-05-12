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
      # Beide Theming-Backends schreiben nach ~/.cache/matugen/colors-gtk.css
      gtk3.extraCss = ''@import url("file://${config.home.homeDirectory}/.cache/matugen/colors-gtk.css");'';
      gtk4.extraCss = ''@import url("file://${config.home.homeDirectory}/.cache/matugen/colors-gtk.css");'';
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
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
