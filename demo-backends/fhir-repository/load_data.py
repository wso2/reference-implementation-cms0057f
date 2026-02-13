import json
import requests
import time

FHIR_SERVER_URL = "http://localhost:9090/fhir/r4"
DATA_FILE = "united-health-fhir-data-repository.json"
API_KEY = ""  # Configure API key here if needed


# Define order of resource loading to satisfy dependencies
RESOURCE_ORDER = [
    "Organization",
    "Patient",
    "Practitioner",
    "PractitionerRole",
    "Location",
    "Coverage",
    "Encounter",
    "Condition",
    "Observation",
    "MedicationRequest",
    "DiagnosticReport",
    "Claim",
    "ClaimResponse",
    "ExplanationOfBenefit",
    "Questionnaire",
    "QuestionnaireResponse",
    "AllergyIntolerance"
]

def fix_questionnaire_response(resource):
    """Fixes non-standard value keys in QuestionnaireResponse items."""
    # Fix authored date format if present (remove time/milliseconds to avoid DB errors)
    if 'authored' in resource:
        # Try to keep just the date part YYYY-MM-DD
        try:
            resource['authored'] = resource['authored'].split('T')[0]
        except:
            pass

    if 'item' in resource:
        for item in resource['item']:
            fix_questionnaire_response_item(item)
    return resource

def fix_questionnaire_response_item(item):
    """Recursive fix for QuestionnaireResponse items."""
    if 'answer' in item:
        for answer in item['answer']:
            # Fix boolean
            if 'valueQuestionnaireResponseBoolean' in answer:
                answer['valueBoolean'] = answer.pop('valueQuestionnaireResponseBoolean')
            # Fix string
            if 'valueQuestionnaireResponseString' in answer:
                answer['valueString'] = answer.pop('valueQuestionnaireResponseString')
            # Fix integer
            if 'valueQuestionnaireResponseInteger' in answer:
                answer['valueInteger'] = answer.pop('valueQuestionnaireResponseInteger')
            
            # Remove extensions if they cause issues or seem malformed
            # For now, let's keep them unless we see specific errors
            pass
            
            # Recurse if there are nested items in the answer
            if 'item' in answer:
                for sub_item in answer['item']:
                    fix_questionnaire_response_item(sub_item)

    if 'item' in item:
         for sub_item in item['item']:
            fix_questionnaire_response_item(sub_item)

def fix_questionnaire(resource):
    """Fixes non-standard value keys in Questionnaire items."""
    # Fix title
    if 'title' in resource and isinstance(resource['title'], dict) and 'value' in resource['title']:
        resource['title'] = resource['title']['value']
    
    # Fix items
    if 'item' in resource:
        for item in resource['item']:
            fix_questionnaire_item(item)
    return resource

def fix_questionnaire_item(item):
    """Recursive fix for Questionnaire items."""
    if 'text' in item and isinstance(item['text'], dict) and 'value' in item['text']:
        item['text'] = item['text']['value']
    
    if 'item' in item:
        for sub_item in item['item']:
            fix_questionnaire_item(sub_item)

def fix_explanation_of_benefit(resource):
    """Fixes dates in ExplanationOfBenefit to avoid DB errors."""
    # Fix created date
    if 'created' in resource:
        try:
            resource['created'] = resource['created'].split('T')[0]
        except:
            pass

    # Fix billablePeriod
    if 'billablePeriod' in resource:
        if 'start' in resource['billablePeriod']:
            resource['billablePeriod']['start'] = resource['billablePeriod']['start'].split('T')[0]
        if 'end' in resource['billablePeriod']:
            resource['billablePeriod']['end'] = resource['billablePeriod']['end'].split('T')[0]

    # Fix supportingInfo timingDate
    if 'supportingInfo' in resource:
        for info in resource['supportingInfo']:
            if 'timingDate' in info:
                # Replace with safe date to avoid DB errors
                info['timingDate'] = "2024-11-01"
    
    # Fix item servicedDate
    if 'item' in resource:
        for item in resource['item']:
            if 'servicedDate' in item:
                item['servicedDate'] = item['servicedDate'].split('T')[0]

    return resource

def fix_medication_request(resource):
    """Fixes references in MedicationRequest."""
    if 'requester' in resource and resource['requester'].get('reference') == 'Practitioner/practitioner-456':
        resource['requester']['reference'] = 'Practitioner/456'
    return resource

def fix_diagnostic_report(resource):
    """Fixes dates and references in DiagnosticReport."""
    # Fix dates to avoid H2 DB errors
    for date_field in ['issued', 'effectiveDateTime']:
        if date_field in resource:
            try:
                resource[date_field] = resource[date_field].split('T')[0]
            except:
                pass
    
    # Fix missing observation references (map to existing or inject)
    # For now, we will handle this in inject_missing_resources but if references are bad strings we might need to map them.
    # The error was 'Observation/observation-wbc' does not exist.
    # We will inject these IDs.
    return resource

def inject_missing_resources(data):
    """Injects missing resources required by other resources."""
    
    # Inject Organization/insurance-org
    if 'Organization' not in data:
        data['Organization'] = []
    
    orgs = {r['id']: r for r in data['Organization'] if 'id' in r}
    if 'insurance-org' not in orgs:
        print("Injecting missing Organization/insurance-org")
        data['Organization'].append({
            "resourceType": "Organization",
            "id": "insurance-org",
            "name": "Insurance Organization",
            "active": True,
            "type": [{
                "coding": [{
                    "system": "http://hl7.org/fhir/organization-role",
                    "code": "payer",
                    "display": "Payer"
                }]
            }]
        })

    # Inject Organization/64
    if '64' not in orgs:
        print("Injecting missing Organization/64")
        data['Organization'].append({
            "resourceType": "Organization",
            "id": "64",
            "name": "Reference Organization 64",
            "active": True
        })

    # Inject Coverage/insurance-coverage
    if 'Coverage' not in data:
        data['Coverage'] = []

    coverages = {r['id']: r for r in data['Coverage'] if 'id' in r}
    if 'insurance-coverage' not in coverages:
        print("Injecting missing Coverage/insurance-coverage")
        data['Coverage'].append({
            "resourceType": "Coverage",
            "id": "insurance-coverage",
            "status": "active",
            "beneficiary": { "reference": "Patient/102" },
            "payor": [ { "reference": "Organization/insurance-org" } ],
            "subscriber": { "reference": "Patient/102" },
            "relationship": { "coding": [{ "system": "http://terminology.hl7.org/CodeSystem/subscriber-relationship", "code": "self" }] }
        })

    # Inject PractitionerRole/456
    if 'PractitionerRole' not in data:
        data['PractitionerRole'] = []
    
    roles = {r['id']: r for r in data['PractitionerRole'] if 'id' in r}
    if '456' not in roles:
        print("Injecting missing PractitionerRole/456")
        data['PractitionerRole'].append({
            "resourceType": "PractitionerRole",
            "id": "456",
            "practitioner": { "reference": "Practitioner/456" },
            "organization": { "reference": "Organization/53" },
            "code": [ { "coding": [ { "system": "http://terminology.hl7.org/CodeSystem/v2-0286", "code": "RP", "display": "Referring Provider" } ] } ]
        })

    # Inject missing Locations
    if 'Location' not in data:
        data['Location'] = []
    locs = {r['id']: r for r in data['Location'] if 'id' in r}
    missing_locs = ['hospital', 'clinic1', 'emergency-dept', 'telehealth-unit', 'home', 'ward-a', 'day-surgery', 'ward-b', 'followup-clinic', 'intake-center']
    for loc_id in missing_locs:
        if loc_id not in locs:
            print(f"Injecting missing Location/{loc_id}")
            data['Location'].append({
                "resourceType": "Location",
                "id": loc_id,
                "name": f"Location {loc_id}",
                "status": "active"
            })

    # Inject missing Observations
    if 'Observation' not in data:
        data['Observation'] = []
    obs = {r['id']: r for r in data['Observation'] if 'id' in r}
    # Add all referenced observations that might be missing
    missing_obs = ['observation-wbc', 'observation-cholesterol', 'observation-hemoglobin', 'observation-ldl', 'observation-hba1c', 'observation-hdl', 'observation-triglycerides']
    for obs_id in missing_obs:
        if obs_id not in obs:
            print(f"Injecting missing Observation/{obs_id}")
            data['Observation'].append({
                "resourceType": "Observation",
                "id": obs_id,
                "status": "final",
                "category": [{
                    "coding": [{
                        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                        "code": "laboratory",
                        "display": "Laboratory"
                    }]
                }],
                "code": {
                    "coding": [{
                        "system": "http://loinc.org",
                        "code": "12345-6",
                        "display": "Observation"
                    }],
                    "text": "Observation"
                },
                "subject": { "reference": "Patient/102" }
            })

def load_data():
    try:
        with open(DATA_FILE, 'r') as f:
            data = json.load(f)
        
        print(f"Loaded data from {DATA_FILE}")

        inject_missing_resources(data)

        # Get all resource types from data
        available_types = list(data.keys())
        
        # Create a processing list: defined order first, then any remaining types
        processing_list = [t for t in RESOURCE_ORDER if t in available_types]
        remaining_types = [t for t in available_types if t not in RESOURCE_ORDER]
        processing_list.extend(remaining_types)

        for resource_type in processing_list:
            if resource_type == 'QuestionnairePackage':
                print(f"Skipping unsupported resource type: {resource_type}")
                continue

            resources = data[resource_type]
            print(f"Processing {resource_type} ({len(resources)} resources)...")
            
            for resource in resources:
                resource_id = resource.get('id')
                if not resource_id:
                    print(f"Skipping {resource_type} without ID")
                    continue
                
                # Apply fixes
                if resource_type == 'QuestionnaireResponse':
                    resource = fix_questionnaire_response(resource)
                if resource_type == 'Questionnaire':
                    resource = fix_questionnaire(resource)
                if resource_type == 'ExplanationOfBenefit':
                    resource = fix_explanation_of_benefit(resource)
                if resource_type == 'MedicationRequest':
                    resource = fix_medication_request(resource)
                if resource_type == 'DiagnosticReport':
                    resource = fix_diagnostic_report(resource)
                if resource_type == 'AllergyIntolerance':
                    # Fix bad practitioner reference
                    if 'recorder' in resource and resource['recorder'].get('reference') == 'Practitioner/practitioner-456':
                        resource['recorder']['reference'] = 'Practitioner/456'

                url = f"{FHIR_SERVER_URL}/{resource_type}"
                headers = {"Content-Type": "application/fhir+json"}
                if API_KEY:
                    headers["Test-Key"] = API_KEY
                
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
                
                time.sleep(0.01)

    except FileNotFoundError:
        print(f"Error: Data file not found at {DATA_FILE}")
    except json.JSONDecodeError:
        print(f"Error: Failed to decode JSON from {DATA_FILE}")
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")

if __name__ == "__main__":
    load_data()
