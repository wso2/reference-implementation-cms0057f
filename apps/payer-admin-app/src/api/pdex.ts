// PDEX Data Exchange API Client
const API_BASE_URL = window.config?.PDEX_API_URL || 'http://localhost:8091/pdex';

// Export Summary types
export interface OutputFile {
  type: string;
  url: string;
  count: number;
}

export interface ExportSummary {
  transactionTime: string;
  request: string;
  requiresAccessToken: boolean;
  output: OutputFile[];
  deleted?: OutputFile[];
  error?: OutputFile[];
}

// Backend API response structure
export interface PdexDataRequestAPI {
  requestId: string;
  payerId: string;
  memberId: string;
  oldPayerName: string;
  oldPayerState: string;
  oldCoverageId: string;
  coverageStartDate: string;
  coverageEndDate: string;
  bulkDataSyncStatus: 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'FAILED';
  consent: 'GRANTED' | 'DENIED' | 'PENDING';
  createdDate: string;
  exportSummary?: string;
}

// Frontend display structure
export interface PdexDataRequest {
  exchangeId: string;
  syncStatus: 'Finished' | 'In Progress' | 'Error' | 'Pending';
  patientId: string;
  patientName: string;
  payerName: string;
  payerId: string;
  dateSubmitted: string;
  // Additional fields from API
  oldPayerState?: string;
  oldCoverageId?: string;
  coverageStartDate?: string;
  coverageEndDate?: string;
  consent: 'GRANTED' | 'DENIED' | 'PENDING';
  exportSummary?: ExportSummary;
}

/**
 * Map API response to frontend structure
 */
function mapApiResponseToRequest(apiRequest: PdexDataRequestAPI): PdexDataRequest {
  // Map sync status
  let syncStatus: PdexDataRequest['syncStatus'];
  switch (apiRequest.bulkDataSyncStatus) {
    case 'COMPLETED':
      syncStatus = 'Finished';
      break;
    case 'IN_PROGRESS':
      syncStatus = 'In Progress';
      break;
    case 'FAILED':
      syncStatus = 'Error';
      break;
    case 'PENDING':
    default:
      syncStatus = 'Pending';
      break;
  }

  // Parse export summary if available
  let exportSummary: ExportSummary | undefined;
  if (apiRequest.exportSummary) {
    try {
      exportSummary = JSON.parse(apiRequest.exportSummary);
    } catch (err) {
      console.error('Failed to parse export summary:', err);
    }
  }

  return {
    exchangeId: apiRequest.requestId,
    syncStatus,
    patientId: apiRequest.memberId,
    patientName: '', // Not provided in API response
    payerName: apiRequest.oldPayerName,
    payerId: apiRequest.payerId,
    dateSubmitted: apiRequest.createdDate,
    oldPayerState: apiRequest.oldPayerState,
    oldCoverageId: apiRequest.oldCoverageId,
    coverageStartDate: apiRequest.coverageStartDate,
    coverageEndDate: apiRequest.coverageEndDate,
    consent: apiRequest.consent,
    exportSummary,
  };
}

export interface PdexDataRequestsResponse {
  count: number;
  next: string | null;
  previous: string | null;
  results: PdexDataRequestAPI[];
}

export interface PdexDataRequestsMappedResponse {
  results: PdexDataRequest[];
  count: number;
  next: string | null;
  previous: string | null;
}

export interface ErrorPayload {
  timestamp: string;
  status: number;
  reason: string;
  message: string;
  path: string;
  method: string;
}

/**
 * Get all PDEX data requests with pagination
 */
export async function getPdexDataRequests(
  limit: number = 10,
  offset: number = 0
): Promise<PdexDataRequestsMappedResponse> {
  const response = await fetch(
    `${API_BASE_URL}/pdex-data-requests?limit=${limit}&offset=${offset}`
  );

  if (!response.ok) {
    const error: ErrorPayload = await response.json();
    throw new Error(error.message || 'Failed to fetch PDEX data requests');
  }

  const data: PdexDataRequestsResponse = await response.json();
  
  return {
    results: data.results.map(mapApiResponseToRequest),
    count: data.count,
    next: data.next,
    previous: data.previous,
  };
}

/**
 * Get a specific PDEX data request by ID
 */
export async function getPdexDataRequest(requestId: string): Promise<PdexDataRequest> {
  const response = await fetch(`${API_BASE_URL}/pdex-data-requests/${requestId}`);

  if (!response.ok) {
    const error: ErrorPayload = await response.json();
    throw new Error(error.message || 'Failed to fetch PDEX data request');
  }

  const apiRequest: PdexDataRequestAPI = await response.json();
  return mapApiResponseToRequest(apiRequest);
}

/**
 * Trigger data exchange for a specific request
 */
export async function triggerDataExchange(requestId: string): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/trigger-data-exchange/${requestId}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error: ErrorPayload = await response.json();
    throw new Error(error.message || 'Failed to trigger data exchange');
  }
}
