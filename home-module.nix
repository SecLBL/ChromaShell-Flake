inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.programs.chromashell;

  dotfilesSource = inputs.dotfiles;
  qsPkg = inputs.quickshell.packages.${pkgs.system}.default;
in
{
  imports = [
    (import ./home-modules/packages.nix inputs)
    (import ./home-modules/hyprland.nix inputs)
    (import ./home-modules/dotfiles.nix inputs)
    (import ./home-modules/theming.nix inputs)
  ];

  options.programs.chromashell = {
    enable = mkEnableOption "ChromaShell Hyprland/Quickshell/Matugen desktop";
  };
}
