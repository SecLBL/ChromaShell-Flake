inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;
  dotfilesSource = inputs.dotfiles;
  dots = "${dotfilesSource}/dots/.config";
in
{
  config = mkIf cfg.enable {
    xdg.configFile = {
      # ── Quickshell ─────────────────────────────────────────────────────────
      "quickshell".source = pkgs.runCommand "chromashell-qs-patched" {
        buildInputs = [ pkgs.bash ];
      } ''
        cp -r ${dots}/quickshell $out
        chmod -R +w $out
        patchShebangs $out
      '';

      # ── Matugen ────────────────────────────────────────────────────────────
      "matugen".source = "${dots}/matugen";

      # ── Hyprland ───────────────────────────────────────────────────────────
      "hypr/chromashell.conf".source = "${dots}/hypr/hyprland.conf";
      "hypr/config".source          = "${dots}/hypr/config";
      "hypr/scripts".source         = "${dots}/hypr/scripts";

      # ── Kitty ──────────────────────────────────────────────────────────────
      "kitty".source = "${dots}/kitty";

      # ── Fish ───────────────────────────────────────────────────────────────
      "fish/conf.d/chromashell.fish".source = "${dots}/fish/conf.d/chromashell.fish";
    };
  };
}
