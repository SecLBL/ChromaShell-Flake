{
  description = "ChromaShell — Hyprland/Quickshell/Matugen desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    dotfiles = {
      url = "github:SecLBL/ChromaShell";
      flake = false;
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dotfiles, quickshell, ... }@inputs: {
    homeManagerModules.default = import ./home-module.nix inputs;
  };
}
