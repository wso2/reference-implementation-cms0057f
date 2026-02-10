import json
import requests
import time

FHIR_SERVER_URL = "http://localhost:9090/fhir/r4"
DATA_FILE = "../../demo-backends/fhir-data-backend/united-health-fhir-data-repository.json"

def load_data():
    try:
        with open(DATA_FILE, 'r') as f:
            data = json.load(f)
        
        print(f"Loaded data from {DATA_FILE}")

        for resource_type, resources in data.items():
            print(f"Processing {resource_type} ({len(resources)} resources)...")
            for resource in resources:
                resource_id = resource.get('id')
                if not resource_id:
                    print(f"Skipping {resource_type} without ID")
                    continue
                
                url = f"{FHIR_SERVER_URL}/{resource_type}"
                # Use PUT to create/update by ID to be idempotent, or POST if server preferred
                # Reference implementation service.bal shows POST support. 
                # Ideally we check if it exists or just POST. 
                # Let's try POSTing to the type endpoint.
                
                headers = {"Content-Type": "application/fhir+json"}
                try:
                    response = requests.post(url, json=resource, headers=headers)
                    if response.status_code in [200, 201]:
                        print(f"Successfully loaded {resource_type}/{resource_id}")
                    elif response.status_code == 409:
                         print(f"Resource {resource_type}/{resource_id} already exists")
                    else:
                        print(f"Failed to load {resource_type}/{resource_id}: {response.status_code} - {response.text}")
                except Exception as e:
                     print(f"Error loading {resource_type}/{resource_id}: {str(e)}")
                
                # Small delay to not overwhelm the server if needed
                time.sleep(0.01)

    except FileNotFoundError:
        print(f"Error: Data file not found at {DATA_FILE}")
    except json.JSONDecodeError:
        print(f"Error: Failed to decode JSON from {DATA_FILE}")
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")

if __name__ == "__main__":
    load_data()
