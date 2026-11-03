// canvas: Hyprland side of the ChromaShell canvas (hypr/scripts/canvas).
//
// A floating window is drawn, and takes clicks, only on its own monitor.
// Hyprland draws a floating window on every monitor it overlaps. With a panned
// canvas (hypr/scripts/canvas) that paints windows over the neighbouring
// monitor; this cuts them off at their monitor's edge instead.
//
// Left alone: the window being dragged with the mouse (so it can still be
// dragged over), pinned windows, and windows Hyprland animates to another monitor.
//
// hl.plugin.canvas.cursor("grabbing") shows a cursor shape until
// hl.plugin.canvas.cursor() clears it (the Lua pan grabs the canvas with it).
//
// hl.plugin.canvas.pan(ws, dx, dy) posts the IPC event "canvaspan>>ws,dx,dy":
// a canvas moved, the shell follows with its wallpaper parallax.
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/managers/EventManager.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/output/Monitor.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/layout/LayoutManager.hpp>
#include <hyprland/src/layout/supplementary/DragController.hpp>
#include <hyprland/src/layout/target/Target.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/pointer/cursor/CursorShapeOverrideController.hpp>
#include <lua.hpp>

static HANDLE         PHANDLE      = nullptr;
static CFunctionHook* g_renderHook = nullptr;
static CFunctionHook* g_boxHook    = nullptr;

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static bool beingDragged(const PHLWINDOW& w) {
    const auto& drag = g_layoutManager->dragController();
    if (!drag || drag->mode() != MBIND_MOVE)
        return false;
    const auto target = drag->target();
    return target && target->window() == w;
}

static bool clipped(const PHLWINDOW& w) {
    return w->m_isFloating && !w->m_pinned && w->m_monitorMovedFrom == -1 && w->m_monitor && !beingDragged(w);
}

// IHyprRenderer::shouldRenderWindow(PHLWINDOW, PHLMONITOR): also gates borders and shadows
typedef bool (*origShouldRender)(void*, PHLWINDOW, PHLMONITOR);
static bool hkShouldRenderWindow(void* thisptr, PHLWINDOW w, PHLMONITOR m) {
    const bool render = ((origShouldRender)g_renderHook->m_original)(thisptr, w, m);
    if (!render || !w || !m || !clipped(w))
        return render;
    return w->m_monitor == m;
}

// CWindow::getWindowBoxUnified(props): the hit box for clicks/hover (ViewHitTester)
typedef CBox (*origBox)(void*, uint64_t);
static CBox hkGetWindowBoxUnified(void* thisptr, uint64_t props) {
    const CBox box = ((origBox)g_boxHook->m_original)(thisptr, props);
    const auto w   = static_cast<Desktop::View::CWindow*>(thisptr)->m_self.lock();
    if (!w || !clipped(w))
        return box;
    const auto mon = w->m_monitor.lock();
    return box.intersection(CBox{mon->m_position, mon->m_size});
}

// same override slot Hyprland uses for its own window drag ("grabbing")
static int luaCursor(lua_State* L) {
    if (lua_isstring(L, 1))
        Pointer::Cursor::overrideController->setOverride(lua_tostring(L, 1), Pointer::Cursor::CURSOR_OVERRIDE_SPECIAL_ACTION);
    else
        Pointer::Cursor::overrideController->unsetOverride(Pointer::Cursor::CURSOR_OVERRIDE_SPECIAL_ACTION);
    return 0;
}

static int luaPan(lua_State* L) {
    g_pEventManager->postEvent(SHyprIPCEvent{"canvaspan", std::format("{},{},{}", luaL_checkinteger(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3))});
    return 0;
}

static void* findFn(const std::string& name, const std::string& demangledNeedle) {
    for (const auto& fn : HyprlandAPI::findFunctionsByName(PHANDLE, name))
        if (fn.demangled.find(demangledNeedle) != std::string::npos)
            return fn.address;
    throw std::runtime_error("[canvas] function not found: " + demangledNeedle);
}

static void fail(const std::string& reason) {
    HyprlandAPI::addNotification(PHANDLE, "[canvas] " + reason, CHyprColor{1.0, 0.2, 0.2, 1.0}, 8000);
    throw std::runtime_error("[canvas] " + reason);
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    if (std::string{__hyprland_api_get_hash()} != __hyprland_api_get_client_hash())
        fail("built for a different Hyprland version, rebuild the plugin");

    g_renderHook = HyprlandAPI::createFunctionHook(PHANDLE, findFn("shouldRenderWindow", "shouldRenderWindow(Hyprutils::Memory::CSharedPointer<Desktop::View::CWindow>, Hyprutils::Memory::CSharedPointer"),
                                                   (void*)hkShouldRenderWindow);
    g_boxHook    = HyprlandAPI::createFunctionHook(PHANDLE, findFn("getWindowBoxUnified", "CWindow::getWindowBoxUnified("), (void*)hkGetWindowBoxUnified);

    if (!g_renderHook || !g_renderHook->hook() || !g_boxHook || !g_boxHook->hook())
        fail("could not hook Hyprland, wrong version?");

    if (!HyprlandAPI::addLuaFunction(PHANDLE, "canvas", "cursor", luaCursor) || !HyprlandAPI::addLuaFunction(PHANDLE, "canvas", "pan", luaPan))
        fail("could not register hl.plugin.canvas functions");

    return {"canvas", "Canvas helpers: monitor-clipped floating windows, pan cursor and parallax event", "ChromaShell", "1.2"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    // hooks are removed by Hyprland on unload
}
