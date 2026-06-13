{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf mkDefault types;
  cfg = config.programs.chromashell-system;
in
{
  options.programs.chromashell-system = {
    enable = mkEnableOption "ChromaShell system-level configuration";

    hyprland.enable = mkOption {
      type    = types.bool;
      default = true;
      description = ''
        Enable Hyprland (with UWSM) and the Hyprland XDG desktop portal.
        Set to false to provide your own programs.hyprland and xdg.portal config.
      '';
    };

    desktop.enable = mkOption {
      type    = types.bool;
      default = true;
      description = ''
        Enable the caelestia-shell runtime prerequisites: geoclue2 (QtPositioning),
        upower (battery status) and dconf (dark/light mode detection).
        Set to false to manage these services yourself.
      '';
    };

    audio.enable = mkOption {
      type    = types.bool;
      default = true;
      description = ''
        Enable the PipeWire stack (with ALSA/Pulse/JACK + WirePlumber), rtkit and
        the LV2 path that the ChromaShell audio pipeline depends on, plus the
        WirePlumber default sink/source. Set to false to bring your own PipeWire stack.
      '';
    };
  };

  config = mkIf cfg.enable (lib.mkMerge [

    ##########################################################################
    # Always on — ChromaShell-authored system bits
    ##########################################################################
    {

    # Secret Service provider for Electron apps (Element, Slack, …) and system tools.
    # PAM integration unlocks the keyring automatically on login via the display manager.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;

    services.power-profiles-daemon.enable = true;

    # i2c-dev module + udev rules so ddcutil can control monitor brightness via DDC/CI.
    # The user still needs to be in the i2c group (set in NixOS-Configuration_2).
    hardware.i2c.enable = true;

    # gpu-screen-recorder's kms server needs cap_sys_admin to capture via KMS.
    # Without this, it prompts for polkit which fails when launched without a terminal.
    security.wrappers.gsr-kms-server = {
      owner        = "root";
      group        = "root";
      capabilities = "cap_sys_admin+ep";
      source       = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
    };

    # Patch element-desktop's app.asar so it injects ~/.config/chromashell/theming/runtime/element.css
    # into every renderer window. The CSS is written by chromashell-posthook.sh on each
    # theme change. This overlay must live here (NixOS level) because useGlobalPkgs=true
    # in HM means HM nixpkgs.overlays are ignored.
    nixpkgs.overlays = [
      (_final: prev: {
        element-desktop = prev.element-desktop.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ prev.asar ];
          postFixup = (old.postFixup or "") + ''
            tmpdir=$(mktemp -d)
            ${prev.asar}/bin/asar extract "$out/share/element/app.asar" "$tmpdir"
            cat >> "$tmpdir/lib/electron-main.js" << 'CHROMASHELL_EOF'

// ChromaShell: inject ~/.config/chromashell/theming/runtime/element.css on every page load
{
  const _cssPath = path.join(process.env["XDG_CONFIG_HOME"] ?? path.join(app.getPath("home"), ".config"), "chromashell", "theming", "runtime", "element.css");
  app.on("browser-window-created", (_, win) => {
    win.webContents.on("did-finish-load", () => {
      try {
        if (fs.existsSync(_cssPath)) {
          win.webContents.insertCSS(fs.readFileSync(_cssPath, "utf8")).catch(() => {});
        }
      } catch {}
    });
  });
}
CHROMASHELL_EOF
            ${prev.asar}/bin/asar pack "$tmpdir" "$out/share/element/app.asar"
            rm -rf "$tmpdir"
          '';
        });
      })
    ];
    }

    ##########################################################################
    # Hyprland + XDG portal  (programs.chromashell-system.hyprland.enable)
    ##########################################################################
    (mkIf cfg.hyprland.enable {
      programs.hyprland = {
        enable   = mkDefault true;
        withUWSM = mkDefault true;
      };

      # XDG portals for Hyprland (screensharing, file picker, …).
      xdg.portal = {
        enable = mkDefault true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          kdePackages.xdg-desktop-portal-kde
        ];
      };

      # Force Wayland in Electron/Chromium apps.
      environment.sessionVariables.NIXOS_OZONE_WL = mkDefault "1";
    })

    ##########################################################################
    # caelestia-shell prerequisites  (programs.chromashell-system.desktop.enable)
    ##########################################################################
    (mkIf cfg.desktop.enable {
      services.geoclue2.enable = mkDefault true;  # QtPositioning (night light / location)
      services.upower.enable   = mkDefault true;  # battery status
      programs.dconf.enable    = mkDefault true;  # dark/light mode detection
    })

    ##########################################################################
    # Audio stack  (programs.chromashell-system.audio.enable)
    ##########################################################################
    (mkIf cfg.audio.enable {
      security.rtkit.enable = mkDefault true;
      services.pipewire = {
        enable            = mkDefault true;
        alsa.enable       = mkDefault true;
        alsa.support32Bit = mkDefault true;
        pulse.enable      = mkDefault true;
        jack.enable       = mkDefault true;
        wireplumber.enable = mkDefault true;

        # Default sink/source for the ChromaShell audio chains.
        wireplumber.extraConfig."10-chromashell-defaults" = {
          "wireplumber.settings" = {
            "default.configured.audio.sink"   = "MixBus.input";
            "default.configured.audio.source" = "mic_chain_out";
          };
        };
      };

      # LV2 bundles installed by the HM audio module land under ~/.lv2; the system
      # also links /lib/lv2 so host tools (jalv/lv2ls) find them on PATH.
      environment.pathsToLink = [ "/lib/lv2" ];
    })

  ]);
}
