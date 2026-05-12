inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable          = true;
      systemd.enable  = true;
      xwayland.enable = true;
      extraConfig = ''
        source = ${config.xdg.configHome}/hypr/chromashell.conf
      '';
    };

    # Erstellt ~/.config/hypr/custom/ mit leeren Dateien falls noch nicht vorhanden.
    # Diese Dateien gehören dem User — HM fasst sie danach nie wieder an.
    home.activation.chromashell-custom-init = lib.hm.dag.entryAfter ["writeBoundary"] ''
      custom="${config.xdg.configHome}/hypr/custom"
      $DRY_RUN_CMD mkdir -p "$custom"
      for f in monitors.conf env.conf rules.conf keybindings.conf autostart.conf; do
        if [[ ! -f "$custom/$f" ]]; then
          $DRY_RUN_CMD cp "${inputs.dotfiles}/dots/.config/hypr/custom/$f" "$custom/$f"
        fi
      done
    '';
  };
}
