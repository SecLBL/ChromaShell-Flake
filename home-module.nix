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

  # Same pattern for communication apps — disables the built-in discord/whatsapp entries.
  mkCommsEntry = name: cmd: classes: {
    discord.enable  = false;
    whatsapp.enable = false;
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
    zen       = { package = inputs.zen-browser.packages.${system}.default; type = "gecko"; };
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

  # Per-app definitions for the communication workspace toggle.
  # Discord-based clients all reuse the "discord" toggle key with their specific class/command.
  # caeConfig for non-default apps uses mkCommsEntry to disable the discord/whatsapp defaults.
  commsDefs = {
    # ── Discord clients ────────────────────────────────────────────────────
    discord = {
      package   = pkgs.discord;
      caeConfig = {
        discord  = { enable = true; match = [{ class = "discord"; }];  command = [ "discord" ];  move = true; };
        whatsapp.enable = false;
      };
    };
    vencord = {
      # manage=true installs vesktop, the official standalone Vencord desktop app
      package   = pkgs.vesktop;
      caeConfig = {
        discord  = { enable = true; match = [{ class = "vesktop"; }];  command = [ "vesktop" ];  move = true; };
        whatsapp.enable = false;
      };
    };

    equicord = {
      # manage=true installs equibop, the official standalone Equicord desktop app
      package   = pkgs.equibop;
      caeConfig = {
        discord  = { enable = true; match = [{ class = "equibop"; }]; command = [ "equibop" ]; move = true; };
        whatsapp.enable = false;
      };
    };
    legcord = {
      package   = pkgs.legcord;
      caeConfig = {
        discord  = { enable = true; match = [{ class = "legcord"; }]; command = [ "legcord" ]; move = true; };
        whatsapp.enable = false;
      };
    };

    # ── Other messaging ────────────────────────────────────────────────────
    element = {
      package   = pkgs.element-desktop;
      caeConfig = mkCommsEntry "element"  [ "element-desktop" ]  [ "Element" "element-desktop" ];
    };
    telegram = {
      package   = pkgs.telegram-desktop;
      caeConfig = mkCommsEntry "telegram" [ "telegram-desktop" ] [ "TelegramDesktop" "telegram-desktop" ];
    };
    slack = {
      package   = pkgs.slack;
      caeConfig = mkCommsEntry "slack"    [ "slack" ]            [ "Slack" "slack" ];
    };
    signal = {
      package   = pkgs.signal-desktop;
      caeConfig = mkCommsEntry "signal"   [ "signal-desktop" ]   [ "Signal" "signal-desktop" ];
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

    comms = {
      manage = mkOption {
        type        = types.bool;
        default     = false;
        description = "Install the communication app via the flake. false = user manages installation themselves";
      };
      app = mkOption {
        type = types.nullOr (types.enum [
          "discord" "vencord" "equicord" "legcord"   # Discord clients
          "element"                                                     # Matrix
          "telegram" "slack" "signal"                                     # Other
        ]);
        default     = null;
        description = ''
          Communication app for the Super+Shift+C toggle workspace.
            null              — flake does nothing (no install, no caelestia config)
            app + manage=false — caelestia configured for the app, user installs it
            app + manage=true  — flake installs the app and configures caelestia
          Note: vencord installs vesktop (standalone Vencord app) when manage=true.
          Note: equicord installs equibop (standalone Equicord app) when manage=true.

          Note: slack requires nixpkgs.config.allowUnfree = true.
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
      # firefox/librewolf installed via HM modules; zen + chromium-based via home.packages
      lib.optionals
        (cfg.browser.manage && cfg.browser.app != null
         && browserDefs.${cfg.browser.app} ? package
         && (browserDefs.${cfg.browser.app}.type == "chromium" || cfg.browser.app == "zen"))
        [ browserDefs.${cfg.browser.app}.package ]
      ++
      lib.optionals
        (cfg.comms.manage && cfg.comms.app != null && commsDefs.${cfg.comms.app} ? package)
        [ commsDefs.${cfg.comms.app}.package ];

    # ── ChromaShell SSE server ────────────────────────────────────────────────────
    # Serves scheme.json (GET /) and pushes live color updates (GET /events) via SSE.
    # Watches scheme.json via inotifywait and broadcasts to all connected clients.
    systemd.user.services.chromashell-color-server = {
      Unit = {
        Description = "ChromaShell colors SSE server";
        After       = [ "default.target" ];
      };
      Service = {
        ExecStart  = "${pkgs.python3}/bin/python3 ${inputs.dotfiles}/dots/.config/chromashell/theming/sse-server.py";
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
      # Firefox Release rejects unsigned sideloaded extensions; enterprise policies bypass this.
      policies.ExtensionSettings = {
        "chromafox@chromashell" = {
          installation_mode = "force_installed";
          install_url = "http://127.0.0.1:29847/chromafox.xpi";
        };
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

    # ── Browser extension — stable XPI path + profile sideload where unsigned is allowed ─
    # Firefox uses enterprise policies (install_url) → needs XPI at a stable home path.
    # LibreWolf disables signature checks → sideload into profile extensions/ still works.
    home.file =
      lib.optionalAttrs (cfg.browser.app != null &&
                         browserDefs.${cfg.browser.app}.type == "gecko") {
        ".local/share/chromafox/chromafox@chromashell.xpi".source =
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
            local profiles_ini="$1" userchrome_src="$2" allow_unsigned="$3" zen_colors="$4"
            [ -f "$profiles_ini" ] || return 0
            local base rel dir
            base=$(${pkgs.coreutils}/bin/dirname "$profiles_ini")
            rel=$(${pkgs.gawk}/bin/awk -F= '/^Path=/{print $2; exit}' "$profiles_ini" 2>/dev/null)
            [ -n "$rel" ] || return 0
            dir="$base/$rel"
            ${pkgs.coreutils}/bin/mkdir -p "$dir/chrome" "$dir/extensions"
            if [ "$zen_colors" = "true" ]; then
              ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/chromashell/theming/runtime"
              [ -f "$HOME/.config/chromashell/theming/runtime/zen-colors.css" ] || \
                printf ':root {}\n' > "$HOME/.config/chromashell/theming/runtime/zen-colors.css"
              ${pkgs.coreutils}/bin/ln -sf "$HOME/.config/chromashell/theming/runtime/zen-colors.css" \
                "$dir/chrome/zen-colors.css"
              ${pkgs.coreutils}/bin/rm -f "$dir/chrome/userChrome.css"
              { printf '@import url("zen-colors.css");\n\n'; ${pkgs.coreutils}/bin/cat "$userchrome_src"; } \
                > "$dir/chrome/userChrome.css"
            else
              ${pkgs.coreutils}/bin/ln -sf "$userchrome_src" "$dir/chrome/userChrome.css"
            fi
            if [ "$allow_unsigned" = "false" ]; then
              ${pkgs.coreutils}/bin/mkdir -p "$base/policies"
              printf '{"policies":{"ExtensionSettings":{"chromafox@chromashell":{"installation_mode":"force_installed","install_url":"http://127.0.0.1:29847/chromafox.xpi"}}}}' \
                > "$base/policies/policies.json"
            else
              ${pkgs.coreutils}/bin/cp -f "${chromaFoxExt}/chromafox@chromashell.xpi" \
                "$dir/extensions/chromafox@chromashell.xpi"
            fi
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
              "${inputs.dotfiles}/dots/.config/firefox/userChrome.css" "false" "false"
          ''}
          ${lib.optionalString (cfg.browser.app == "librewolf") ''
            deploy_chromafox "$HOME/.librewolf/profiles.ini" \
              "${inputs.dotfiles}/dots/.config/firefox/userChrome.css" "true" "false"
          ''}
          ${lib.optionalString (cfg.browser.app == "zen") ''
            deploy_chromafox "$HOME/.config/zen/profiles.ini" \
              "${inputs.dotfiles}/dots/.config/zen/userChrome.css" "true" "true"
          ''}
        ''
    );

    # ── Element: force gnome-libsecret so the keyring is found on Hyprland ──────
    # Electron does not auto-detect the Secret Service on non-GNOME desktops;
    # overriding the desktop entry is more reliable than electron-flags.conf.
    xdg.desktopEntries.element-desktop = mkIf (cfg.comms.app == "element") {
      name        = "Element";
      genericName = "Matrix Client";
      comment     = "Feature-rich client for Matrix.org";
      exec        = "element-desktop --password-store=gnome-libsecret %u";
      icon        = "element";
      categories  = [ "Network" "InstantMessaging" "Chat" ];
      mimeType    = [ "x-scheme-handler/element" "x-scheme-handler/io.element.desktop" ];
    };

    # On NixOS, XKB rules live under /run/current-system/sw, not /usr/share.
    # The QML already checks this env var before falling back to the hardcoded path.
    # Drop-in instead of systemd.user.services.caelestia.environment — the caelestia-shell
    # module uses the raw Service={} format, so .environment generates a spurious [environment]
    # section that systemd rejects.
    xdg.configFile."systemd/user/caelestia.service.d/xkb-path.conf".text = ''
      [Service]
      Environment="CAELESTIA_XKB_RULES_PATH=/run/current-system/sw/share/X11/xkb/rules/base.lst"
    '';

    # XDG Desktop Portal looks in XDG_DATA_HOME/applications for the app ID desktop file.
    # quickshell's desktop file is in the nix store but not linked into the user profile,
    # so the portal can't find it and refuses to register the app.
    xdg.dataFile."applications/org.quickshell.desktop".text = ''
      [Desktop Entry]
      Version=1.5
      Type=Application
      NoDisplay=true
      Name=Quickshell
      Icon=org.quickshell
    '';

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
            postHook =
              let
                browserArg = lib.optionalString (cfg.browser.app != null) " --browser ${cfg.browser.app}";
                commsArg   = lib.optionalString (cfg.comms.app   != null) " --comms ${cfg.comms.app}";
              in
                "bash ${inputs.dotfiles}/dots/.config/chromashell/theming/posthook.sh${browserArg}${commsArg}";
          };
        } // lib.optionalAttrs (cfg.music.app != null || cfg.comms.app != null) {
          toggles =
            lib.optionalAttrs (cfg.music.app != null) { music = musicDefs.${cfg.music.app}.caeConfig; }
            // lib.optionalAttrs (cfg.comms.app != null) { communication = commsDefs.${cfg.comms.app}.caeConfig; };
        };
      };
    };
  };
}
