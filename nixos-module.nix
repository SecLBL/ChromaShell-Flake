{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.programs.chromashell-system;
in
{
  options.programs.chromashell-system.enable = mkEnableOption "ChromaShell system-level configuration";

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable   = true;
      withUWSM = true;
    };

    services.pipewire.wireplumber.extraConfig."10-chromashell-defaults" = {
      "wireplumber.settings" = {
        "default.configured.audio.sink"   = "MixBus.input";
        "default.configured.audio.source" = "mic_chain_out";
      };
    };

    # Secret Service provider for Electron apps (Element, Slack, …) and system tools.
    # PAM integration unlocks the keyring automatically on login via the display manager.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
