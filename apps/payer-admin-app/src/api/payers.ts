const API_BASE_URL = window.config?.BFF_URL || 'http://localhost:6091/v1';

export interface PayerFormData {
  name: string;
  email: string;
  address?: string;
  state?: string;
  fhir_server_url: string;
  app_client_id: string;
  app_client_secret: string;
  smart_config_url: string;
  scopes: string | null;
}

export interface Payer extends PayerFormData {
  id: string;
  created_at: string;
  updated_at: string;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  totalCount: number;
  totalPages: number;
}

export interface PayerListResponse {
  data: Payer[];
  pagination: PaginationMeta;
}

export interface ErrorPayload {
  timestamp: string;
  status: number;
  reason: string;
  message: string;
  path: string;
  method: string;
}

class PayersAPI {
  private async request<T>(
    endpoint: string,
    options?: RequestInit
  ): Promise<T> {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    });

    if (!response.ok) {
      const error: ErrorPayload = await response.json().catch(() => ({
        timestamp: new Date().toISOString(),
        status: response.status,
        reason: response.statusText,
        message: 'An error occurred',
        path: endpoint,
        method: options?.method || 'GET',
      }));
      throw error;
    }

    if (response.status === 204) {
      return undefined as T;
    }

    return response.json();
  }

  async getPayers(params?: {
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<PayerListResponse> {
    const queryParams = new URLSearchParams();
    if (params?.search) queryParams.append('search', params.search);
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());

    const query = queryParams.toString();
    return this.request<PayerListResponse>(
      `/payers${query ? `?${query}` : ''}`
    );
  }

  async getPayer(payerId: string): Promise<Payer> {
    return this.request<Payer>(`/payers/${payerId}`);
  }

  async createPayer(data: PayerFormData): Promise<Payer> {
    return this.request<Payer>('/payers', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updatePayer(payerId: string, data: PayerFormData): Promise<Payer> {
    return this.request<Payer>(`/payers/${payerId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deletePayer(payerId: string): Promise<void> {
    return this.request<void>(`/payers/${payerId}`, {
      method: 'DELETE',
    });
  }
}

export const payersAPI = new PayersAPI();
