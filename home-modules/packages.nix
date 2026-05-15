inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.chromashell;
  system = pkgs.stdenv.hostPlatform.system;

  caelestiaPlugin = inputs.caelestia-shell.packages.${system}.caelestia-shell.passthru.plugin;

  quickshellBase = pkgs.quickshell.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ pkgs.qt6.qtmultimedia ];
  });

  quickshell = pkgs.symlinkJoin {
    name = "quickshell-chromashell";
    paths = [ quickshellBase ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/qs \
        --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "${caelestiaPlugin}/lib/qt-6/qml"
    '';
  };
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # ── Shell ────────────────────────────────
      quickshell
      matugen
      awww
      kitty
      fish
      starship

      # ── Hyprland utilities ───────────────────
      rofi
      swayosd
      hyprlock
      hypridle
      wl-clipboard
      cliphist
      grim
      slurp
      satty
      playerctl

      # ── Audio ────────────────────────────────
      jalv
      lsp-plugins
      rnnoise-plugin
      noise-repellent
      pamixer
      pulseaudio      # wpctl / pactl

      # ── Theming ──────────────────────────────
      pywal           # pywal backend
      adw-gtk3

      # ── System / scripting ───────────────────
      inotify-tools
      jq
      socat
      bc
      imagemagick
      curl

      # ── Fonts ────────────────────────────────
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      material-symbols
    ];
  };
}
