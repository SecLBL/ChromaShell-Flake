inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg  = config.programs.chromashell;
  dots = "${inputs.dotfiles}/dots/.config";
in
{
  config = mkIf cfg.enable {

    xdg.configFile = {

      # ── Quickshell ─────────────────────────────────────────────────────
      "quickshell".source = pkgs.runCommand "chromashell-qs-patched" {
        buildInputs = [ pkgs.bash ];
      } ''
        cp -r ${dots}/quickshell $out
        chmod -R +w $out
        patchShebangs $out
      '';

      # ── Hyprland ───────────────────────────────────────────────────────
      "hypr/chromashell.conf".source = "${dots}/hypr/hyprland.conf";
      "hypr/config".source           = "${dots}/hypr/config";
      "hypr/scripts".source          = "${dots}/hypr/scripts";

      # ── Matugen ────────────────────────────────────────────────────────
      "matugen".source = "${dots}/matugen";

      # ── Pipewire virtual nodes ──────────────────────────────────────────
      "pipewire/pipewire.conf.d/loopback.conf".source       = "${dots}/pipewire/pipewire.conf.d/loopback.conf";
      "pipewire/pipewire.conf.d/filter-chain-mic.conf".source  = "${dots}/pipewire/pipewire.conf.d/filter-chain-mic.conf";
      "pipewire/pipewire.conf.d/filter-chain-chat.conf".source = "${dots}/pipewire/pipewire.conf.d/filter-chain-chat.conf";

      # ── Kitty ──────────────────────────────────────────────────────────
      "kitty".source = "${dots}/kitty";

      # ── Fish ───────────────────────────────────────────────────────────
      "fish/conf.d/chromashell.fish".source = "${dots}/fish/conf.d/chromashell.fish";
    };
  };
}
