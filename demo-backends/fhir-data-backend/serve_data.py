import http.server
import socketserver
import json
import os
import sys

PORT = 9091
# Path relative to this script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(SCRIPT_DIR, "united-health-fhir-data-repository.json")

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        try:
            with open(DATA_FILE, 'r') as f:
                data = json.load(f)
            
            # Fix Claim items
            if "Claim" in data:
                print(f"Processing {len(data['Claim'])} Claim resources...")
                for claim in data["Claim"]:
                    if "item" in claim:
                        for item in claim["item"]:
                            if "extension" not in item:
                                # Fix: Add missing extension field
                                # Used empty array to satisfy type 'Extension[]'
                                item["extension"] = []
            
            self.wfile.write(json.dumps(data).encode('utf-8'))
        except Exception as e:
            print(f"Error processing request: {e}")
            self.wfile.write(json.dumps({"error": str(e)}).encode('utf-8'))

    def log_message(self, format, *args):
        # Print logs to stderr to verify it's working
        sys.stderr.write("%s - - [%s] %s\n" %
                         (self.client_address[0],
                          self.log_date_time_string(),
                          format%args))

print(f"Starting server at port {PORT}, serving {DATA_FILE}")
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    httpd.serve_forever()
