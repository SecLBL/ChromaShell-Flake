{ hyprlandPlugins, hyprland }:

# hyprbars from nixpkgs, built against the Hyprland that loads it, with ChromaShell's fixes:
# blur drawn before the stencil (blurring switches it off) and a working stencil mask.
(hyprlandPlugins.override { inherit hyprland; }).hyprbars.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./chromashell.patch ];
})
