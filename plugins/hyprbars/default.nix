{ hyprlandPlugins, hyprland }:

# hyprbars from nixpkgs, built against the Hyprland that loads it, with ChromaShell's fixes:
# a working stencil mask, cleared over the whole bar (rounded blur and sharp icons are upstream since 0.57).
(hyprlandPlugins.override { inherit hyprland; }).hyprbars.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./chromashell.patch ];
})
