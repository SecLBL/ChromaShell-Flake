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
  };
}
