{
  description = "ChromaShell — Hyprland/Caelestia desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Dotfiles — overridden to local path during development via NixOS-Configuration_2
    dotfiles = {
      url = "github:SecLBL/ChromaShell";
      flake = false;
    };

    caelestia-shell = {
      url = "git+file:///home/lbl/System_Maintenance/caelestia/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-cli = {
      url = "git+file:///home/lbl/System_Maintenance/caelestia/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dotfiles, caelestia-shell, caelestia-cli, spicetify-nix, ... }@inputs: {
    homeManagerModules.default = import ./home-module.nix inputs;
    nixosModules.default       = import ./nixos-module.nix;
  };
}
