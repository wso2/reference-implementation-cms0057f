import json
import requests
import os
import glob

FHIR_SERVER_URL = "http://localhost:9090/fhir/r4/StructureDefinition"
DEFINITIONS_DIR = "node_modules/hl7.fhir.us.core"

def load_definitions():
    if not os.path.exists(DEFINITIONS_DIR):
        print(f"Directory {DEFINITIONS_DIR} not found. Please run npm install first.")
        return

    files = glob.glob(os.path.join(DEFINITIONS_DIR, "*.json"))
    print(f"Found {len(files)} JSON files in {DEFINITIONS_DIR}")
    
    count = 0
    for file_path in files:
        try:
            with open(file_path, 'r') as f:
                resource = json.load(f)
            
            if resource.get("resourceType") != "StructureDefinition":
                continue

            resource_id = resource.get("id")
            url = resource.get("url")
            
            print(f"Processing StructureDefinition: {resource_id} ({url})")
            
            # Use PUT if ID exists to update/create, or POST
            # Using POST as per user instructions implicitly (feed into repo)
            # But let's check existence to avoid 409 if possible?
            # Or just POST and ignore 409.
            
            headers = {"Content-Type": "application/fhir+json"}
            
            # Trying POST
            response = requests.post(FHIR_SERVER_URL, json=resource, headers=headers)
            
            if response.status_code in [200, 201]:
                print(f"Successfully loaded {resource_id}")
                count += 1
            elif response.status_code == 409:
                print(f"StructureDefinition {resource_id} already exists (409)")
            else:
                print(f"Failed to load {resource_id}: {response.status_code} - {response.text}")

        except Exception as e:
            print(f"Error processing {file_path}: {str(e)}")

    print(f"Finished loading {count} StructureDefinitions.")

if __name__ == "__main__":
    load_definitions()
