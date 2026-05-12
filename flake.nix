{
  description = "ChromaShell — Hyprland/Quickshell/Matugen desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Dotfiles — overridden to local path during development via NixOS-Configuration_2
    dotfiles = {
      url = "github:SecLBL/ChromaShell";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, dotfiles, ... }@inputs: {
    homeManagerModules.default = import ./home-module.nix inputs;
    nixosModules.default       = import ./nixos-module.nix;
  };
}
