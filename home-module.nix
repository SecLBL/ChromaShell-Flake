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

  # Browser definitions.
  # type "gecko"    → our SSE extension + userChrome deployed
  # type "chromium" → package only; caelestia-cli applies surface color via policy
  # package omitted for Zen (not in nixpkgs; user installs via community flake)
  browserDefs = {
    firefox   = { package = pkgs.firefox;   type = "gecko"; };
    librewolf = { package = pkgs.librewolf; type = "gecko"; };
    zen       = {                            type = "gecko"; };
    brave     = { package = pkgs.brave;     type = "chromium"; };
    chromium  = { package = pkgs.chromium;  type = "chromium"; };
  };

  # Builds ChromaFox (the ChromaShell browser extension) as an XPI for Firefox-based browsers.
  chromaFoxExt = pkgs.runCommand "chromafox" {
    nativeBuildInputs = [ pkgs.zip ];
  } ''
    mkdir -p $out
    cd ${inputs.dotfiles}/extra/chromafox
    zip -r $out/chromafox@chromashell.xpi manifest.json background.js
  '';

  # Editor command used in the Hyprland keybind (Super+C).
  # Terminal editors are wrapped in kitty so they open a window.
  editorDefs = {
    vscodium = { package = pkgs.vscodium;   cmd = "codium"; };
    vscode   = { package = pkgs.vscode;     cmd = "code"; };
    zed      = { package = pkgs.zed-editor; cmd = "zeditor"; };
    micro    = { package = pkgs.micro;      cmd = "kitty -e micro"; };
    helix    = { package = pkgs.helix;      cmd = "kitty -e hx"; };
    neovim   = { package = pkgs.neovim;     cmd = "kitty -e nvim"; };
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

    editor = {
      manage = mkOption {
        type        = types.bool;
        default     = false;
        description = "Install the editor via the flake. false = user manages installation themselves";
      };
      app = mkOption {
        type = types.nullOr (types.enum [
          "vscodium" "vscode"            # GUI — VS Code family
          "zed"                          # GUI — Zed
          "micro"                        # terminal — lightweight
          "helix" "neovim"               # terminal — modal (no config managed by flake)
        ]);
        default     = null;
        description = ''
          Editor launched by Super+C and set as $editor in Hyprland.
            null              — flake does nothing (no install, no keybind override)
            app + manage=false — keybind set to app, user installs it
            app + manage=true  — flake installs the app and sets keybind
          Note: vscode requires nixpkgs.config.allowUnfree = true.
        '';
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

    browser = {
      manage = mkOption {
        type        = types.bool;
        default     = false;
        description = "Install the browser via the flake. false = user manages installation themselves";
      };
      app = mkOption {
        type = types.nullOr (types.enum [
          "firefox" "librewolf" "zen"   # gecko — ChromaShell extension + userChrome deployed
          "brave" "chromium"            # chromium — caelestia-cli apply_chromium
        ]);
        default     = null;
        description = ''
          Browser for daily use.
            null              — flake does nothing (no install, no config deployment)
            app + manage=false — ChromaShell extension and userChrome deployed, user installs browser
            app + manage=true  — flake installs the browser and deploys configs
          Note: zen is not in nixpkgs; manage=true has no effect for zen.
          Note: Firefox release requires signed extensions; the XPI is placed in the profile but
                may not auto-load. Use librewolf for reliable unsigned extension support.
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

    # ── Optional app packages (manage = true) ────────────────────────────────
    home.packages =
      lib.optionals
        (cfg.editor.manage && cfg.editor.app != null)
        [ editorDefs.${cfg.editor.app}.package ]
      ++
      lib.optionals
        (cfg.music.manage && cfg.music.app != null && musicDefs.${cfg.music.app} ? package)
        [ musicDefs.${cfg.music.app}.package ]
      ++
      # Gecko browsers are installed via their HM modules; only chromium-based go here
      lib.optionals
        (cfg.browser.manage && cfg.browser.app != null
         && browserDefs.${cfg.browser.app}.type == "chromium")
        [ browserDefs.${cfg.browser.app}.package ];

    # ── ChromaShell SSE server ────────────────────────────────────────────────────
    # Serves scheme.json (GET /) and pushes live color updates (GET /events) via SSE.
    # Watches scheme.json via inotifywait and broadcasts to all connected clients.
    systemd.user.services.chromashell-color-server = {
      Unit = {
        Description = "ChromaShell colors SSE server";
        After       = [ "default.target" ];
      };
      Service = {
        ExecStart  = "${pkgs.python3}/bin/python3 ${./chromashell-sse-server.py}";
        Environment = [ "PATH=${pkgs.inotify-tools}/bin" ];
        Restart    = "on-failure";
        RestartSec = "2s";
      };
      Install.WantedBy = [ "default.target" ];
    };

    # ── Browser: Firefox (manage = true — HM owns install + profile) ───────────
    programs.firefox = mkIf (cfg.browser.manage && cfg.browser.app == "firefox") {
      enable  = true;
      package = pkgs.firefox;
      profiles.default = {
        userChrome = builtins.readFile "${inputs.dotfiles}/dots/.config/firefox/userChrome.css";
        settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };

    # ── Browser: LibreWolf (manage = true — HM owns install + profile) ──────
    programs.librewolf = mkIf (cfg.browser.manage && cfg.browser.app == "librewolf") {
      enable  = true;
      package = pkgs.librewolf;
      profiles.default = {
        userChrome = builtins.readFile "${inputs.dotfiles}/dots/.config/firefox/userChrome.css";
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "xpinstall.signatures.required" = false;
        };
      };
    };

    # ── Browser extension (gecko, manage = true) — XPI into HM "default" profile ─
    home.file =
      lib.optionalAttrs (cfg.browser.manage && cfg.browser.app == "firefox") {
        ".mozilla/firefox/default/extensions/chromafox@chromashell.xpi".source =
          "${chromaFoxExt}/chromafox@chromashell.xpi";
      } //
      lib.optionalAttrs (cfg.browser.manage && cfg.browser.app == "librewolf") {
        ".librewolf/default/extensions/chromafox@chromashell.xpi".source =
          "${chromaFoxExt}/chromafox@chromashell.xpi";
      };

    # ── Browser (gecko, manage = false) — detect profile, deploy ChromaFox ───
    # manage = false: user owns the browser install; flake parses profiles.ini
    # zen: always via activation (not in nixpkgs, no HM module available)
    home.activation.chromashellBrowserSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.optionalString
        (cfg.browser.app != null
         && browserDefs.${cfg.browser.app}.type == "gecko"
         && (cfg.browser.app == "zen" || !cfg.browser.manage))
        ''
          deploy_chromafox() {
            local profiles_ini="$1" userchrome_src="$2" allow_unsigned="$3"
            [ -f "$profiles_ini" ] || return 0
            local base rel dir
            base=$(${pkgs.coreutils}/bin/dirname "$profiles_ini")
            rel=$(${pkgs.gawk}/bin/awk -F= '/^Path=/{print $2; exit}' "$profiles_ini" 2>/dev/null)
            [ -n "$rel" ] || return 0
            dir="$base/$rel"
            ${pkgs.coreutils}/bin/mkdir -p "$dir/chrome" "$dir/extensions"
            ${pkgs.coreutils}/bin/ln -sf "$userchrome_src" "$dir/chrome/userChrome.css"
            ${pkgs.coreutils}/bin/cp -f "${chromaFoxExt}/chromafox@chromashell.xpi" \
              "$dir/extensions/chromafox@chromashell.xpi"
            ${pkgs.gnugrep}/bin/grep -q "legacyUserProfileCustomizations" "$dir/user.js" 2>/dev/null || \
              printf 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n' \
                >> "$dir/user.js"
            if [ "$allow_unsigned" = "true" ]; then
              ${pkgs.gnugrep}/bin/grep -q "xpinstall.signatures.required" "$dir/user.js" 2>/dev/null || \
                printf 'user_pref("xpinstall.signatures.required", false);\n' \
                  >> "$dir/user.js"
            fi
          }

          ${lib.optionalString (cfg.browser.app == "firefox") ''
            deploy_chromafox "$HOME/.mozilla/firefox/profiles.ini" \
              "${inputs.dotfiles}/dots/.config/firefox/userChrome.css" "false"
          ''}
          ${lib.optionalString (cfg.browser.app == "librewolf") ''
            deploy_chromafox "$HOME/.librewolf/profiles.ini" \
              "${inputs.dotfiles}/dots/.config/firefox/userChrome.css" "true"
          ''}
          ${lib.optionalString (cfg.browser.app == "zen") ''
            deploy_chromafox "$HOME/.zen/profiles.ini" \
              "${inputs.dotfiles}/dots/.config/zen/userChrome.css" "true"
          ''}
        ''
    );

    # ── Caelestia shell + CLI ─────────────────────────────────────────────────
    programs.caelestia = {
      enable  = true;
      package = inputs.caelestia-shell.packages.${system}.caelestia-shell;
      cli = {
        enable  = true;
        package = inputs.caelestia-cli.packages.${system}.default;
        settings = {
          theme = {
            # Spicetify colors are handled by the JS extension via the colors socket.
            # caelestia-cli's apply_spicetify (color.ini) is redundant with spicetify-nix.
            enableSpicetify = lib.mkIf (cfg.music.app == "spicetify") false;
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
