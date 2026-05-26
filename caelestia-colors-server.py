#!/usr/bin/env python3
# Serves ~/.config/spicetify/Themes/caelestia/color.ini over HTTP with CORS headers.
# Used by the caelestia-colors Spicetify extension, which cannot read local files
# directly due to Spotify's sandboxed Electron renderer.
import http.server, socketserver, pathlib, os

PORT = 29847
COLOR_INI = (
    pathlib.Path(os.environ.get("XDG_CONFIG_HOME", ""))
    or pathlib.Path.home() / ".config"
) / "spicetify/Themes/caelestia/color.ini"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            data = COLOR_INI.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
        except Exception:
            self.send_response(404)
            self.end_headers()

    def log_message(self, *args):
        pass


with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
    httpd.serve_forever()
