const API_BASE_URL = window.config?.BFF_URL || 'http://localhost:6091/v1';

import type { Questionnaire, QuestionnaireStatus } from '../types/questionnaire';

export interface QuestionnaireListItem {
  id: string;
  title: string;
  description?: string;
  status: QuestionnaireStatus;
  createdAt?: string;
  updatedAt?: string;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  totalCount: number;
  totalPages: number;
}

export interface QuestionnaireListResponse {
  data: QuestionnaireListItem[];
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

class QuestionnairesAPI {
  private async request<T>(
    endpoint: string,
    options?: RequestInit
  ): Promise<T> {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/fhir+json',
        ...options?.headers,
      },
    });

    if (!response.ok && response.status !== 201) {
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

    if (response.status === 204 || response.status === 201) {
      return undefined as T;
    }

    return response.json();
  }

  async getQuestionnaires(params?: {
    search?: string;
    status?: QuestionnaireStatus;
    page?: number;
    limit?: number;
  }): Promise<QuestionnaireListResponse> {
    const queryParams = new URLSearchParams();
    if (params?.search) queryParams.append('search', params.search);
    if (params?.status) queryParams.append('status', params.status);
    if (params?.page) queryParams.append('page', params.page.toString());
    if (params?.limit) queryParams.append('limit', params.limit.toString());

    const query = queryParams.toString();
    return this.request<QuestionnaireListResponse>(
      `/questionnaires${query ? `?${query}` : ''}`
    );
  }

  async getQuestionnaire(questionnaireId: string): Promise<Questionnaire> {
    return this.request<Questionnaire>(`/questionnaires/${questionnaireId}`);
  }

  async createQuestionnaire(data: Questionnaire): Promise<Questionnaire> {
    return this.request<Questionnaire>('/questionnaires', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateQuestionnaire(questionnaireId: string, data: Questionnaire): Promise<Questionnaire> {
    return this.request<Questionnaire>(`/questionnaires/${questionnaireId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteQuestionnaire(questionnaireId: string): Promise<void> {
    return this.request<void>(`/questionnaires/${questionnaireId}`, {
      method: 'DELETE',
    });
  }
}

export const questionnairesAPI = new QuestionnairesAPI();
