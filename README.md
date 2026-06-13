# ChromaShell-Flake

The deployment side of [ChromaShell](https://github.com/SecLBL/ChromaShell).
The dotfiles repo on its own isn't a working system — this flake is what turns
it into one. It pulls the dotfiles in, installs the packages, ships my forks of
the Caelestia shell and CLI, wires up theming and keybinds, and symlinks
everything into place.

It's built around the [Caelestia](https://github.com/caelestia-dots) shell and
CLI — most of what makes the desktop tick is their work, not mine. This flake
just packages it all up and adds my own bits on top.

There are two modules:

- **Home Manager module** (`programs.chromashell`) — the actual desktop: shell,
  CLI, dotfiles, audio pipeline, theming, and the app picking.
- **NixOS module** (`programs.chromashell-system`) — the system-level bits the
  desktop needs: Hyprland, the PipeWire stack, portals, keyring, and a few
  hardware/app fixes.

You don't strictly need the NixOS module if you already have a working
Hyprland + PipeWire system, but it saves you wiring those up by hand.

## Usage

Add the flake as an input and import both modules. A combined NixOS +
Home Manager setup looks like this:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    chromashell.url = "github:SecLBL/ChromaShell-Flake";
    chromashell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, chromashell, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # System-level (Hyprland, PipeWire, portals, …)
        chromashell.nixosModules.default
        {
          programs.chromashell-system.enable = true;
          nixpkgs.config.allowUnfree = true;   # needed for vscode / slack
        }

        # Home Manager
        home-manager.nixosModules.home-manager
        {
          home-manager.users.you = { ... }: {
            imports = [ chromashell.homeManagerModules.default ];

            programs.chromashell = {
              enable = true;

              # Pick your apps (see the lists below).
              browser = { app = "librewolf"; manage = true; };
              comms   = { app = "vencord";   manage = true; };
              music   = { app = "spicetify"; manage = true; };
              editor  = { app = "zed";       manage = true; };
            };

            home.stateVersion = "24.11";
          };
        }
      ];
    };
  };
}
```

If you run Home Manager standalone, just import
`chromashell.homeManagerModules.default` into your HM config and set
`programs.chromashell` the same way — and bring your own Hyprland/PipeWire, or
add the NixOS module separately.

## Home Manager module — `programs.chromashell`

| Option | Default | What it does |
|--------|---------|--------------|
| `enable` | `false` | Turn on the whole desktop. |
| `audio.enable` | `true` | Deploy the PipeWire filter-chain audio pipeline. |
| `browser.{app,manage}` | `null` / `false` | Daily browser — see below. |
| `comms.{app,manage}` | `null` / `false` | Chat app — see below. |
| `music.{app,manage}` | `null` / `false` | Music app — see below. |
| `editor.{app,manage}` | `null` / `false` | Editor — see below. |

> The `true`-by-default options here (and in the NixOS module below) are opt-out
> for a reason: they're not really optional. If you disable them, the matching
> shell features will almost certainly just stop working — unless you go and
> write your own replacements for them.

### How app picking works

Each app category has two settings — `app` and `manage`:

- `app = null` — the flake does nothing for that category.
- `app = "..."`, `manage = false` — the flake wires the app into the desktop
  (keybind, Caelestia integration, configs) but **you install it yourself**.
- `app = "..."`, `manage = true` — the flake also **installs** the app.

So if you already manage your packages elsewhere, leave `manage = false` and the
flake just handles the integration.

**Browsers** (`browser.app`) — gecko ones get the ChromaFox extension +
userChrome, chromium ones get their surface color via caelestia-cli:
`firefox`, `librewolf`, `zen`, `brave`, `chromium`.

**Communication** (`comms.app`), bound to `Super+Shift+C`:
`discord`, `vencord`, `equicord`, `legcord`, `element`, `telegram`, `slack`,
`signal`.

**Music** (`music.app`), bound to `Super+M`:
`spotify`, `spicetify`, `tidal-hifi`, `nuclear`, `feishin`, `strawberry`,
`elisa`, `rhythmbox`, `lollypop`, `audacious`, `deadbeef`, `amberol`.

**Editors** (`editor.app`), launched by `Super+C`:
`vscodium`, `vscode`, `zed`, `micro`, `helix`, `neovim`.

### Which ones actually work well

The combo I use, and that's properly themed: **librewolf / brave**,
**vencord / element**, **spicetify**, **zed**, **vscodium**. Stick to these for
the best experience.

Everything else in the lists still gets correctly wired into Caelestia
(keybinds, workspaces, app matching), but it isn't properly themed yet — that's
still WIP.

A few practical notes: release Firefox needs signed extensions, so the ChromaFox
XPI may not auto-load (use librewolf instead); `zen` isn't in nixpkgs, so
`manage = true` is a no-op (install it via the community flake); `vencord`
installs vesktop and `equicord` installs equibop when managed; `vscode` and
`slack` need `allowUnfree`.

## NixOS module — `programs.chromashell-system`

Provides the system-level prerequisites. The blocks below are `true` by default
and can be turned off if you already provide your own equivalent — but, same as
the Home Manager options, disabling them will break the shell features that
depend on them unless you wire up replacements yourself.

| Option | Default | What it does |
|--------|---------|--------------|
| `enable` | `false` | Turn on the system config. |
| `hyprland.enable` | `true` | Hyprland (with UWSM) + the Hyprland XDG portal. |
| `desktop.enable` | `true` | caelestia-shell runtime deps: geoclue2, upower, dconf. |
| `audio.enable` | `true` | PipeWire (ALSA/Pulse/JACK + WirePlumber), rtkit, the LV2 path, and the default sink/source for the audio chains. |

It also always sets up a few things the desktop relies on: the GNOME keyring
(secret storage for Electron apps, unlocked on login), power-profiles-daemon,
i2c/DDC for monitor brightness, a capability wrapper for gpu-screen-recorder's
KMS capture, and a small overlay that injects live theming CSS into
element-desktop.

## Local development

The dotfiles input is a plain (non-flake) source, so you can point it at a local
checkout while iterating instead of pushing to GitHub every time:

```nix
chromashell.inputs.dotfiles.follows = "...";  # or override the input directly
```

## Credits

Same as the dotfiles repo — this is mostly a wrapper around other people's work:

- **[Caelestia](https://github.com/caelestia-dots)** — the shell and CLI this
  whole thing is built around. The vast majority of the credit goes here.
- **End-4 / [illogical-impulse](https://github.com/end-4/dots-hyprland)** — for
  the inspiration that got me started.
