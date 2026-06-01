inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;

  jalvPath = lib.makeBinPath [
    pkgs.jalv
    pkgs.pipewire
    pkgs.pipewire.jack
    pkgs.jq
    pkgs.coreutils
    pkgs.bash
  ];
in
{
  config = mkIf (cfg.enable && cfg.audio.enable) {

    # LV2-Plugin-Symlinks ins Home-Verzeichnis (jalv sucht hier)
    home.file = {
      ".lv2/lsp-plugins.lv2".source     = "${pkgs.lsp-plugins}/lib/lv2/lsp-plugins.lv2";
      ".lv2/rnnoise_mono.lv2".source    = "${pkgs.rnnoise-plugin}/lib/lv2/rnnoise_mono.lv2";
      ".lv2/rnnoise_stereo.lv2".source  = "${pkgs.rnnoise-plugin}/lib/lv2/rnnoise_stereo.lv2";
      ".lv2/nrepellent.lv2".source      = "${pkgs.noise-repellent}/lib/lv2/nrepellent.lv2";
      ".lv2/fil4.lv2".source            = "${pkgs.x42-plugins}/lib/lv2/fil4.lv2";
    };

    # jalv plugin chain — starts with WirePlumber, restarts on PipeWire crash
    systemd.user.services.chromashell-jalv = {
      Unit = {
        Description = "ChromaShell jalv LV2 audio plugin chain";
        After    = [ "wireplumber.service" "pipewire.service" ];
        PartOf   = [ "wireplumber.service" ];
        Requires = [ "wireplumber.service" "pipewire.service" ];
      };
      Service = {
        Type        = "simple";
        ExecStart   = "${config.xdg.configHome}/chromashell/audio/start-jalv.sh";
        Restart     = "on-failure";
        RestartSec  = "3s";
        Environment = [ "PATH=${jalvPath}" ];
        StandardOutput = "journal";
        StandardError  = "journal";
      };
      Install.WantedBy = [ "wireplumber.service" ];
    };

  };
}
