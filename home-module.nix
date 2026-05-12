inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.programs.chromashell;
in
{
  imports = [
    (import ./home-modules/packages.nix  inputs)
    (import ./home-modules/hyprland.nix  inputs)
    (import ./home-modules/audio.nix     inputs)
    (import ./home-modules/dotfiles.nix  inputs)
    (import ./home-modules/theming.nix   inputs)
  ];

  options.programs.chromashell = {
    enable = mkEnableOption "ChromaShell Hyprland/Quickshell/Matugen desktop";

    theme = mkOption {
      type    = types.enum [ "matugen" "pywal" ];
      default = "matugen";
      description = "Active theming backend — matugen (Material You) or pywal";
    };

    audio = {
      enable = mkOption {
        type    = types.bool;
        default = true;
        description = "Deploy jalv plugin chain and pipewire virtual nodes";
      };
    };
  };
}
