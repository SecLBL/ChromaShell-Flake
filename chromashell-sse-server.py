#!/usr/bin/env python3
# ChromaShell SSE server — serves caelestia's scheme.json over HTTP and pushes
# live updates via Server-Sent Events whenever the file changes.
#
#   GET /        → current scheme.json (application/json)
#   GET /events  → SSE stream; sends current colors on connect, then on every change
import http.server
import os
import pathlib
import queue
import subprocess
import threading

PORT  = 29847
STATE = (
    pathlib.Path(os.environ.get("XDG_STATE_HOME") or (os.path.expanduser("~") + "/.local/state"))
    / "caelestia/scheme.json"
)

_clients: list[queue.Queue] = []
_lock = threading.Lock()


def _watcher() -> None:
    while True:
        subprocess.run(
            ["inotifywait", "-e", "close_write", "-q", str(STATE)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:
            data = STATE.read_text()
        except OSError:
            continue
        with _lock:
            for q in _clients[:]:
                try:
                    q.put_nowait(data)
                except queue.Full:
                    pass


threading.Thread(target=_watcher, daemon=True).start()


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/events":
            self._sse()
        else:
            self._json()

    def _json(self) -> None:
        try:
            data = STATE.read_bytes()
        except OSError:
            self.send_response(404)
            self.end_headers()
            return
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(data)

    def _sse(self) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        q: queue.Queue = queue.Queue(maxsize=4)
        with _lock:
            _clients.append(q)
        try:
            # Send current colors immediately on connect
            self.wfile.write(f"data: {STATE.read_text()}\n\n".encode())
            self.wfile.flush()
            while True:
                self.wfile.write(f"data: {q.get()}\n\n".encode())
                self.wfile.flush()
        except Exception:
            pass
        finally:
            with _lock:
                try:
                    _clients.remove(q)
                except ValueError:
                    pass

    def log_message(self, *args) -> None:
        pass


if __name__ == "__main__":
    with http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler) as httpd:
        httpd.serve_forever()
