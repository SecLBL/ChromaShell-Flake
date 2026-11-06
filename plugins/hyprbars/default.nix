{ hyprlandPlugins, hyprland }:

# hyprbars from nixpkgs, built against the Hyprland that loads it, with ChromaShell's fixes:
# rounded blur behind the bar (Hyprland's is square at the corners), working stencil, sharp icons.
(hyprlandPlugins.override { inherit hyprland; }).hyprbars.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./chromashell.patch ];
})
