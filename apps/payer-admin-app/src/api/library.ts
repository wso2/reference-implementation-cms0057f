// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const API_BASE_URL = (window as any).config?.BFF_URL || 'http://localhost:6091/v1';

export interface FHIRLibrary {
  resourceType: 'Library';
  id?: string;
  url?: string;
  name?: string;
  title?: string;
  status: 'draft' | 'active' | 'retired' | 'unknown';
  type?: {
    coding?: Array<{ system?: string; code?: string; display?: string }>;
  };
  content?: Array<{
    contentType?: string;
    data?: string; // base64-encoded CQL
  }>;
}

export interface FHIRValueSet {
  resourceType: 'ValueSet';
  id?: string;
  url?: string;
  name?: string;
  title?: string;
  status: 'draft' | 'active' | 'retired' | 'unknown';
  compose?: {
    include?: Array<{
      system?: string;
      concept?: Array<{ code?: string; display?: string }>;
    }>;
  };
}

class LibraryAPI {
  private async request<T>(endpoint: string, options?: RequestInit): Promise<T> {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/fhir+json',
        ...options?.headers,
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    if (response.status === 204) {
      return undefined as T;
    }

    return response.json();
  }

  async getLibraryById(libraryId: string): Promise<FHIRLibrary> {
    return this.request<FHIRLibrary>(`/libraries/${encodeURIComponent(libraryId)}`);
  }

  async getLibraryByUrl(url: string): Promise<FHIRLibrary> {
    return this.request<FHIRLibrary>(`/libraries?url=${encodeURIComponent(url)}`);
  }

  async createLibrary(library: FHIRLibrary): Promise<FHIRLibrary> {
    return this.request<FHIRLibrary>('/libraries', {
      method: 'POST',
      body: JSON.stringify(library),
    });
  }

  async updateLibrary(libraryId: string, library: FHIRLibrary): Promise<FHIRLibrary> {
    return this.request<FHIRLibrary>(`/libraries/${encodeURIComponent(libraryId)}`, {
      method: 'PUT',
      body: JSON.stringify(library),
    });
  }

  async deleteLibrary(libraryId: string): Promise<void> {
    return this.request<void>(`/libraries/${encodeURIComponent(libraryId)}`, {
      method: 'DELETE',
    });
  }

  async getValueSetByUrl(url: string): Promise<FHIRValueSet> {
    return this.request<FHIRValueSet>(`/value-sets?url=${encodeURIComponent(url)}`);
  }

  async createValueSet(valueSet: FHIRValueSet): Promise<FHIRValueSet> {
    return this.request<FHIRValueSet>('/value-sets', {
      method: 'POST',
      body: JSON.stringify(valueSet),
    });
  }

  async updateValueSet(valueSetId: string, valueSet: FHIRValueSet): Promise<FHIRValueSet> {
    return this.request<FHIRValueSet>(`/value-sets/${encodeURIComponent(valueSetId)}`, {
      method: 'PUT',
      body: JSON.stringify(valueSet),
    });
  }
}

export const libraryAPI = new LibraryAPI();

// --- CQL Utilities ---

/**
 * Decode base64-encoded CQL from a FHIR Library's content.
 * Returns empty string if no text/cql content is found.
 */
export function decodeCqlFromLibrary(library: FHIRLibrary): string {
  const cqlContent = library.content?.find(
    (c) => c.contentType === 'text/cql'
  );
  if (!cqlContent?.data) {
    return '';
  }
  try {
    const binaryString = atob(cqlContent.data);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return new TextDecoder().decode(bytes);
  } catch {
    return '';
  }
}

/**
 * Encode CQL string to base64 for storing in a FHIR Library.
 */
export function encodeCqlToBase64(cql: string): string {
  const bytes = new TextEncoder().encode(cql);
  let binaryString = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binaryString += String.fromCharCode(bytes[i]);
  }
  return btoa(binaryString);
}

/**
 * Parse all `define "Name"` statements from CQL text.
 * Returns an array of define names (without surrounding quotes).
 */
export function parseCqlDefines(cql: string): string[] {
  const defines: string[] = [];
  const regex = /^define\s+"([^"]+)"/gm;
  let match;
  while ((match = regex.exec(cql)) !== null) {
    defines.push(match[1]);
  }
  return defines;
}

/**
 * Parse CQL text into individual define blocks.
 * Each block contains the define name and its full text (including the `define "X":` line).
 */
export function extractDefineBlocks(cql: string): Array<{ name: string; body: string }> {
  const lines = cql.split('\n');
  const blocks: Array<{ name: string; body: string }> = [];
  let currentName: string | null = null;
  let currentLines: string[] = [];

  for (const line of lines) {
    const m = line.match(/^define\s+"([^"]+)"\s*:/);
    if (m) {
      if (currentName !== null) blocks.push({ name: currentName, body: currentLines.join('\n').trim() });
      currentName = m[1];
      currentLines = [line];
    } else if (currentName !== null) {
      currentLines.push(line);
    }
  }
  if (currentName !== null) blocks.push({ name: currentName, body: currentLines.join('\n').trim() });
  return blocks;
}

/**
 * Extract the preamble (everything before the first `define` statement) from CQL text.
 */
export function extractCqlPreamble(cql: string): string {
  const m = cql.match(/^define\s+"/m);
  if (!m || m.index === undefined) return cql.trimEnd();
  return cql.substring(0, m.index).trimEnd();
}

/**
 * Reconstruct CQL from a preamble string and an ordered list of define blocks.
 */
export function reconstructCql(
  preamble: string,
  blocks: Array<{ name: string; body: string }>,
): string {
  if (blocks.length === 0) return preamble;
  return [preamble, ...blocks.map((b) => b.body)].join('\n\n');
}

/**
 * Extract the Library ID from a canonical URL such as
 * https://example.com/fhir/Library/my-library-id
 */
export function extractLibraryIdFromUrl(canonicalUrl: string): string | null {
  const match = canonicalUrl.match(/\/Library\/([^/?#]+)/);
  return match?.[1] ?? null;
}

/**
 * Extract the cqf-library canonical URL from a FHIR Questionnaire's extensions.
 */
export function extractLibraryUrlFromQuestionnaire(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  questionnaire: { extension?: Array<{ url?: string; valueCanonical?: string }> }
): string | null {
  return (
    questionnaire.extension?.find(
      (e) => e.url === 'http://hl7.org/fhir/StructureDefinition/cqf-library'
    )?.valueCanonical ?? null
  );
}

/**
 * Build a FHIR Library resource shell ready for create/update.
 * Embeds the CQL as base64-encoded content.
 */
export function buildLibraryResource(params: {
  id?: string;
  name: string;
  title: string;
  url: string;
  cql: string;
}): FHIRLibrary {
  // Strip all non-alphanumeric characters — same as the CQL enrichment engine
  const cleanName = params.name.replace(/[^a-zA-Z0-9]/g, '');
  // ID convention: lowercase alphanumeric + "-prepopulation"  (e.g. "vyepticoveragecriteria-prepopulation")
  const id = params.id ?? `${cleanName.toLowerCase()}-prepopulation`;
  // FHIR name convention: PascalCase + "Prepopulation"  (e.g. "VyeptiCoverageCriteriaPrepopulation")
  const fhirName = `${cleanName}Prepopulation`;

  return {
    resourceType: 'Library',
    id,
    url: params.url,
    name: fhirName,
    title: params.title,
    status: 'active',
    type: {
      coding: [
        {
          system: 'http://terminology.hl7.org/CodeSystem/library-type',
          code: 'logic-library',
          display: 'Logic Library',
        },
      ],
    },
    content: [
      {
        contentType: 'text/cql',
        data: encodeCqlToBase64(params.cql),
      },
    ],
  };
}
