import http.server, socketserver, os

PORT = 8081
DIR  = os.path.dirname(os.path.abspath(__file__))

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIR, **kwargs)

    def send_response(self, code, message=None):
        super().send_response(code, message)
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")

    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("", PORT), NoCacheHandler) as httpd:
    print(f"Serving http://0.0.0.0:{PORT} — no-cache")
    httpd.serve_forever()
