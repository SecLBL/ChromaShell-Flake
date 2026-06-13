{
  description = "ChromaShell — Hyprland/Caelestia desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Dotfiles — can be overridden to a local path during development via inputs.dotfiles.follows
    dotfiles = {
      url = "github:SecLBL/ChromaShell";
      flake = false;
    };

    caelestia-shell = {
      url = "github:SecLBL/CS-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-cli = {
      url = "github:SecLBL/CS-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dotfiles, caelestia-shell, caelestia-cli, spicetify-nix, zen-browser, ... }@inputs: {
    homeManagerModules.default = import ./home-module.nix inputs;
    nixosModules.default       = import ./nixos-module.nix;
  };
}
