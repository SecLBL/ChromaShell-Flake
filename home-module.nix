inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg    = config.programs.chromashell;
  system = pkgs.stdenv.hostPlatform.system;

  # Build a caelestia CLI toggle entry for an app not in caelestia's defaults.
  # Disables the built-in spotify and feishin entries so only the chosen app runs.
  mkEntry = name: cmd: classes: {
    spotify.enable = false;
    feishin.enable = false;
    ${name} = {
      enable  = true;
      match   = map (c: { class = c; }) classes;
      command = cmd;
      move    = true;
    };
  };

  # Per-app definitions.
  # package: omitted for spicetify (provided by programs.spicetify via spicetify-nix).
  # caeConfig: written to cli.json → toggles.music — overrides caelestia defaults.
  musicDefs = {
    # ── Streaming ─────────────────────────────────────────────────────────────
    spotify = {
      package   = pkgs.spotify;
      caeConfig = {
        spotify = { enable = true; command = [ "spotify" ]; };
        feishin.enable = false;
      };
    };
    spicetify = {
      # Binary is still "spotify" after patching; package via programs.spicetify.
      caeConfig = {
        spotify = { enable = true; command = [ "spotify" ]; };
        feishin.enable = false;
      };
    };
    tidal-hifi = {
      package   = pkgs.tidal-hifi;
      caeConfig = mkEntry "tidal-hifi" [ "tidal-hifi" ] [ "tidal-hifi" ];
    };
    nuclear = {
      package   = pkgs.nuclear;
      caeConfig = mkEntry "nuclear" [ "nuclear" ] [ "nuclear" "Nuclear" ];
    };

    # ── Self-hosted streaming clients ─────────────────────────────────────────
    feishin = {
      package   = pkgs.feishin;
      caeConfig = {
        spotify.enable = false;
        feishin.enable = true;
      };
    };

    # ── Local library players ─────────────────────────────────────────────────
    strawberry = {
      package   = pkgs.strawberry;
      caeConfig = mkEntry "strawberry" [ "strawberry" ] [ "strawberry" "Strawberry" ];
    };
    elisa = {
      package   = pkgs.elisa;
      caeConfig = mkEntry "elisa" [ "elisa" ] [ "elisa" "org.kde.elisa" ];
    };
    rhythmbox = {
      package   = pkgs.rhythmbox;
      caeConfig = mkEntry "rhythmbox" [ "rhythmbox" ] [ "rhythmbox" "Rhythmbox" ];
    };
    lollypop = {
      package   = pkgs.lollypop;
      caeConfig = mkEntry "lollypop" [ "lollypop" ] [ "Lollypop" "org.gnome.Lollypop" ];
    };
    audacious = {
      package   = pkgs.audacious;
      caeConfig = mkEntry "audacious" [ "audacious" ] [ "audacious" "Audacious" ];
    };
    deadbeef = {
      package   = pkgs.deadbeef;
      caeConfig = mkEntry "deadbeef" [ "deadbeef" ] [ "deadbeef" "DeaDBeeF" ];
    };
    amberol = {
      package   = pkgs.amberol;
      caeConfig = mkEntry "amberol" [ "amberol" ] [ "io.bassi.Amberol" "amberol" ];
    };
  };
in
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
    inputs.spicetify-nix.homeManagerModules.default
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

    music = {
      manage = mkOption {
        type        = types.bool;
        default     = false;
        description = "Install the music app via the flake. false = user manages installation themselves";
      };
      app = mkOption {
        type = types.nullOr (types.enum [
          "spotify" "spicetify"                          # streaming — Spotify
          "tidal-hifi" "nuclear"                         # streaming — other
          "feishin"                                      # self-hosted (Jellyfin/Navidrome)
          "strawberry" "elisa" "rhythmbox" "lollypop"   # local library
          "audacious" "deadbeef" "amberol"               # local library — lightweight
        ]);
        default     = null;
        description = ''
          Music app for the Super+M special workspace.
            null       — flake does nothing for music (no install, no caelestia config)
            app + manage=false — caelestia configured for the app, user installs it
            app + manage=true  — flake installs the app and configures caelestia
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    # ── Spicetify via spicetify-nix (only when manage = true) ────────────────
    programs.spicetify = mkIf (cfg.music.manage && cfg.music.app == "spicetify") {
      enable               = true;
      alwaysEnableDevTools = true;
      theme = {
        name          = "caelestia";
        src           = "${inputs.dotfiles}/dots/.config/spicetify/Themes/caelestia";
        injectCss     = true;
        replaceColors = true;
        homeConfig    = true;
        colorScheme   = "caelestia";
      };
      enabledExtensions = [
        {
          src  = "${inputs.dotfiles}/dots/.config/spicetify/Extensions";
          name = "caelestia-colors.js";
        }
      ];
    };

    # ── Music app package (manage = true, non-spicetify) ─────────────────────
    home.packages = lib.optionals
      (cfg.music.manage && cfg.music.app != null && musicDefs.${cfg.music.app} ? package)
      [ musicDefs.${cfg.music.app}.package ];

    # ── Caelestia shell + CLI ─────────────────────────────────────────────────
    programs.caelestia = {
      enable  = true;
      package = inputs.caelestia-shell.packages.${system}.caelestia-shell;
      cli = {
        enable  = true;
        package = inputs.caelestia-cli.packages.${system}.default;
        settings = {
          theme = {
            postHook = ''
              primary=$(jq -r '.primary' <<< "$SCHEME_COLOURS")
              surface=$(jq -r '.surface' <<< "$SCHEME_COLOURS")
              printf 'return {\n  active_border   = "rgba(%sFF)",\n  inactive_border = "rgba(%s00)",\n}\n' "$primary" "$surface" > "$HOME/.config/hypr/colors.lua"
              hyprctl reload
            '';
          };
        } // lib.optionalAttrs (cfg.music.app != null) {
          toggles.music = musicDefs.${cfg.music.app}.caeConfig;
        };
      };
    };
  };
}
