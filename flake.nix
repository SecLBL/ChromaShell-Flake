{
  description = "ChromaShell — Hyprland/Quickshell/Matugen desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Dotfiles — overridden to local path during development via NixOS-Configuration_2
    dotfiles = {
      url = "github:SecLBL/ChromaShell";
      flake = false;
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dotfiles, caelestia-shell, ... }@inputs: {
    homeManagerModules.default = import ./home-module.nix inputs;
    nixosModules.default       = import ./nixos-module.nix;
  };
}
