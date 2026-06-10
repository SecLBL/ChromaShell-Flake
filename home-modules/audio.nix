inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;

  audioPath = lib.makeBinPath [
    pkgs.pipewire
    pkgs.jq
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gawk
    pkgs.bash
  ];
in
{
  config = mkIf (cfg.enable && cfg.audio.enable) {

    # LV2 symlinks kept for manual debugging with jalv/lv2ls; the chains
    # themselves resolve plugins via LV2_PATH/LADSPA_PATH below.
    home.file = {
      ".lv2/lsp-plugins.lv2".source = "${pkgs.lsp-plugins}/lib/lv2/lsp-plugins.lv2";
      ".lv2/fil4.lv2".source        = "${pkgs.x42-plugins}/lib/lv2/fil4.lv2";
    };

    # Audio chains — own PipeWire client instance hosting the filter-chain
    # graphs (chains.conf). Starts with WirePlumber, restarts on crash.
    systemd.user.services.chromashell-audio = {
      Unit = {
        Description = "ChromaShell audio chains (PipeWire filter-chains)";
        After    = [ "wireplumber.service" "pipewire.service" ];
        PartOf   = [ "wireplumber.service" ];
        Requires = [ "wireplumber.service" "pipewire.service" ];
      };
      Service = {
        Type        = "simple";
        ExecStart   = "${config.xdg.configHome}/chromashell/audio/start-audio.sh";
        Restart     = "on-failure";
        RestartSec  = "3s";
        Environment = [
          "PATH=${audioPath}"
          "LADSPA_PATH=${pkgs.deepfilternet}/lib/ladspa"
          "LV2_PATH=${pkgs.lsp-plugins}/lib/lv2:${pkgs.x42-plugins}/lib/lv2"
        ];
        StandardOutput = "journal";
        StandardError  = "journal";
      };
      Install.WantedBy = [ "wireplumber.service" ];
    };

  };
}
