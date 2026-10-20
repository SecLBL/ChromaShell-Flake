inputs:

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkDefault;
  cfg = config.programs.chromashell;
  wp  = cfg.wallpaper;
  caelestia = "${inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/caelestia";
  wallDir   = "${config.home.homeDirectory}/${wp.directory}";
  # Store paths are <hash>-name; link images under their real name
  wallLink  = img: "${wp.directory}/${baseNameOf (toString img)}";

  # Runs `cmd` only when `want` differs from the last applied value, so a
  # choice made in the shell's UI survives rebuilds. Retries on failure.
  applyOnChange = key: want: cmd: ''
    marker="${config.xdg.stateHome}/chromashell/${key}"
    want=${lib.escapeShellArg want}
    if [ "$(cat "$marker" 2>/dev/null)" != "$want" ]; then
      echo "chromashell: applying ${key} ($want)"
      if [ -n "''${DRY_RUN:-}" ]; then :
      elif ${cmd}; then
        mkdir -p "$(dirname "$marker")" && printf '%s' "$want" > "$marker"
      else
        echo "chromashell: could not apply ${key}, retrying on the next switch"
      fi
    fi
  '';
in
{
  config = mkIf cfg.enable {

    # ── Wallpaper ──────────────────────────────────────────────────────────────
    # CLI (paths.py) only reads the env var, the shell prefers it over shell.json
    systemd.user.sessionVariables.CAELESTIA_WALLPAPERS_DIR = wallDir;
    home.sessionVariables.CAELESTIA_WALLPAPERS_DIR         = wallDir;

    # Individual links, so the folder stays writable for your own images
    home.file = lib.listToAttrs (map (img: lib.nameValuePair (wallLink img) { source = img; })
      (lib.unique (wp.images ++ lib.optional (wp.default != null) wp.default)));

    home.activation.chromashellWallpaper = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      ''$DRY_RUN_CMD mkdir -p "${wallDir}"
      '' + lib.optionalString (wp.default != null) (applyOnChange "wallpaper" (toString wp.default)
        ''timeout 60 ${caelestia} wallpaper -f "${config.home.homeDirectory}/${wallLink wp.default}"''));

    systemd.user.services.chromashell-random-wallpaper = mkIf wp.randomOnLogin {
      Unit = {
        Description = "ChromaShell: random wallpaper at login";
        After       = [ "graphical-session.target" "caelestia.service" ];
        PartOf      = [ "graphical-session.target" ];
      };
      # -n: don't skip images smaller than the monitor
      Service = { Type = "oneshot"; ExecStart = "${caelestia} wallpaper -r ${wallDir} -n"; };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # ── Scheme (after the wallpaper: dynamic is generated from it) ────────────
    home.activation.chromashellScheme = mkIf (cfg.scheme.name != null) (
      let
        s    = cfg.scheme;
        args = [ "-n" s.name ]
          ++ lib.optionals (s.flavour != null) [ "-f" s.flavour ]
          ++ lib.optionals (s.variant != null) [ "-v" s.variant ]
          ++ lib.optionals (s.mode    != null) [ "-m" s.mode ];
      in
      lib.hm.dag.entryAfter [ "chromashellWallpaper" ] (applyOnChange "scheme" (toString args)
        "timeout 60 ${caelestia} scheme set ${lib.escapeShellArgs args}"));

    # ── Transparency (merged into the shell-owned shell.json) ─────────────────
    home.activation.chromashellTransparency = mkIf (cfg.transparency.enable != null) (
      let
        want = builtins.toJSON { enabled = cfg.transparency.enable; inherit (cfg.transparency) base layers; };
        shellCfg = "${config.xdg.configHome}/caelestia/shell.json";
      in
      lib.hm.dag.entryAfter [ "chromashellSeedShellApps" ] (applyOnChange "transparency" want ''
        { tmp=$(mktemp) && ${pkgs.jq}/bin/jq --argjson t "$want" '.appearance.transparency = $t' "${shellCfg}" > "$tmp" && mv "$tmp" "${shellCfg}"; }''));

    gtk = {
      enable = true;
      theme  = {
        name    = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name    = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk4.theme = null;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    # hypr/config/variables.lua expects Bibata-Modern-Classic (size 18); without
    # the theme installed Hyprland falls back to a 1px cursor
    home.pointerCursor = mkDefault {
      name    = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size    = 18;
      gtk.enable        = true;
      x11.enable        = true;
      hyprcursor.enable = true;
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk";
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme    = "adw-gtk3-dark";
      };
    };
  };
}
