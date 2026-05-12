inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;
in
{
  config = mkIf (cfg.enable && cfg.audio.enable) {

    # LV2-Plugin-Symlinks ins Home-Verzeichnis (jalv sucht hier)
    home.file = {
      ".lv2/lsp-plugins.lv2".source     = "${pkgs.lsp-plugins}/lib/lv2/lsp-plugins.lv2";
      ".lv2/rnnoise_mono.lv2".source    = "${pkgs.rnnoise-plugin}/lib/lv2/rnnoise_mono.lv2";
      ".lv2/rnnoise_stereo.lv2".source  = "${pkgs.rnnoise-plugin}/lib/lv2/rnnoise_stereo.lv2";
      ".lv2/nrepellent.lv2".source      = "${pkgs.noise-repellent}/lib/lv2/nrepellent.lv2";
    };

    # WirePlumber: Default Sink/Source auf ChromaShell-Nodes
    services.pipewire.wireplumber.extraConfig = {
      "10-chromashell-defaults" = {
        "wireplumber.settings" = {
          "default.configured.audio.sink"   = "MixBus.input";
          "default.configured.audio.source" = "mic_chain_out";
        };
      };
    };
  };
}
