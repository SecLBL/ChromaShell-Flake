inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg    = config.programs.chromashell;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    (import ./home-modules/packages.nix  inputs)
    (import ./home-modules/hyprland.nix  inputs)
    (import ./home-modules/audio.nix     inputs)
    (import ./home-modules/dotfiles.nix  inputs)
    (import ./home-modules/theming.nix   inputs)
  ];

  options.programs.chromashell = {
    enable = mkEnableOption "ChromaShell Hyprland/Caelestia desktop";

    audio = {
      enable = mkOption {
        type    = types.bool;
        default = true;
        description = "Deploy jalv plugin chain and pipewire virtual nodes";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.caelestia = {
      enable  = true;
      package = inputs.caelestia-shell.packages.${system}.caelestia-shell;
      cli = {
        enable  = true;
        package = inputs.caelestia-cli.packages.${system}.default;
        settings = {
          theme = {
            enableHypr = false;
            postHook = ''
              primary=$(jq -r '.primary' <<< "$SCHEME_COLOURS")
              surface=$(jq -r '.surface' <<< "$SCHEME_COLOURS")
              printf 'return {\n  active_border   = "rgba(%sFF)",\n  inactive_border = "rgba(%s00)",\n}\n' "$primary" "$surface" > "$HOME/.config/hypr/colors.lua"
              hyprctl reload
            '';
          };
        };
      };
    };
  };
}
