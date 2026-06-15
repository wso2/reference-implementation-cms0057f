from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class MockEndpoint(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)
        
        print("\n=== RECEIVED NOTIFICATION ===")
        print(json.dumps(json.loads(body), indent=2))
        print("=============================\n")
        
        # Return 200 OK
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"status": "received"}')

if __name__ == '__main__':
    # 8095 (not 8080) to avoid clashing with the local fhir-service on :8080.
    server = HTTPServer(('localhost', 8095), MockEndpoint)
    print('Mock endpoint running on http://localhost:8095')
    server.serve_forever()