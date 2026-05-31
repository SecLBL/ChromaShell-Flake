{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.programs.chromashell-system;
in
{
  options.programs.chromashell-system.enable = mkEnableOption "ChromaShell system-level configuration";

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable   = true;
      withUWSM = true;
    };

    services.pipewire.extraLv2Packages = with pkgs; [ lsp-plugins rnnoise-plugin noise-repellent x42-plugins ];

    services.pipewire.wireplumber.extraConfig."10-chromashell-defaults" = {
      "wireplumber.settings" = {
        "default.configured.audio.sink"   = "MixBus.input";
        "default.configured.audio.source" = "mic_chain_out";
      };
    };

    # Prevent WirePlumber from auto-linking jalv nodes to the default sink/source.
    # start-jalv.sh wires them explicitly via pw-link after all nodes are up.
    services.pipewire.wireplumber.extraConfig."20-chromashell-jalv" = {
      "monitor.rules" = [
        {
          matches = [
            { "node.name" = "mic-gate"; }
            { "node.name" = "mic-nr"; }
            { "node.name" = "mic-comp"; }
            { "node.name" = "chat-nr"; }
            { "node.name" = "chat-comp"; }
            { "node.name" = "general-eq"; }
          ];
          actions = {
            "update-props" = {
              "node.autoconnect" = false;
            };
          };
        }
      ];
    };

    # Secret Service provider for Electron apps (Element, Slack, …) and system tools.
    # PAM integration unlocks the keyring automatically on login via the display manager.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.sddm.enableGnomeKeyring = true;

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
  };
}
