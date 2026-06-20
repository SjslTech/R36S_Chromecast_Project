import http.server
import socketserver
import os

PORT = 8080
DIRECTORY = "/tmp/hls"

class ThreadedCORSRequestHandler(http.server.SimpleHTTPRequestHandler):
	def __init__(self, *args, **kwargs):
		# Serve out of the /tmp/hls directory explicitly
		super().__init__(*args, directory=DIRECTORY, **kwargs)

	def end_headers(self):
		# Inject mandatory CORS headers so the Chromecast doesn't reject the stream
		self.send_header('Access-Control-Allow-Origin', '*')
		self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
		self.send_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, Range')
		self.send_header('Access-Control-Expose-Headers', 'Content-Length, Content-Range')
		super().end_headers()

	def do_OPTIONS(self):
		# Handle the pre-flight check requests sent by the Chromecast
		self.send_response(200)
		self.end_headers()

class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
	# This MixIn spins up a brand new background thread for every single request,
	# preventing the BrokenPipeError from stalling or crashing the main stream.
	daemon_threads = True

if __name__ == "__main__":
	# Ensure the HLS directory exists before spinning up
	os.makedirs(DIRECTORY, exist_ok=True)
	
	with ThreadingHTTPServer(("0.0.0.0", PORT), ThreadedCORSRequestHandler) as httpd:
		print(f"Serving HLS stream out of {DIRECTORY} on port {PORT} (Threaded + CORS active)...")
		try:
			httpd.serve_forever()
		except KeyboardInterrupt:
			print("\nShutting down server.")
