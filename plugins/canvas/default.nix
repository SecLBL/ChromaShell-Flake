{ hyprlandPlugins, hyprland, lua5_4 }:

# Must be built against the exact Hyprland that loads it (checked at load time).
hyprlandPlugins.mkHyprlandPlugin {
  inherit hyprland;
  pluginName = "canvas";
  version = "1.2";
  src = ./.;
  meta.description = "ChromaShell canvas: monitor-clipped floating windows, pan cursor and parallax event";

  buildInputs = [ lua5_4 ];

  dontUseCmakeConfigure = true;
  dontUseMesonConfigure = true;

  buildPhase = ''
    runHook preBuild
    $CXX -shared -fPIC -O2 -std=c++2b -Wno-narrowing -fno-gnu-unique main.cpp -o libcanvas.so \
      $(pkg-config --cflags pixman-1 libdrm hyprland pangocairo libinput libudev wayland-server xkbcommon lua)
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 libcanvas.so $out/lib/libcanvas.so
    runHook postInstall
  '';
}
