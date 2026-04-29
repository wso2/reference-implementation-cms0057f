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

const FILE_SERVICE_URL = window.config?.QUESTIONNAIRE_GEN_API_URL || 'http://localhost:6080';

export interface ConvertResponse {
  job_id: string;
  file_name: string;
  status: string;
  message: string;
}

export interface JobMetadata {
  job_id: string;
  file_name: string;
  status: string;
  created_at: string;
  error_message: string | null;
}

export interface QuestionnaireResponse {
  questionnaires?: unknown;
  failed_scenarios?: unknown;
}

export interface ErrorPayload {
  timestamp: string;
  status: number;
  reason: string;
  message: string;
  path: string;
  method: string;
}

class FileServiceAPI {
  private async request<T>(
    endpoint: string,
    options?: RequestInit
  ): Promise<T> {
    const response = await fetch(`${FILE_SERVICE_URL}${endpoint}`, {
      ...options,
      headers: {
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

    if (response.status === 204) {
      return undefined as T;
    }

    // Handle text/plain responses
    const contentType = response.headers.get('content-type');
    if (contentType?.includes('text/plain')) {
      const text = await response.text();
      return text as T;
    }

    return response.json();
  }

  async convertPdf(files: File[]): Promise<ConvertResponse[]> {
    const formData = new FormData();
    files.forEach(file => formData.append('file', file));

    return this.request<ConvertResponse[]>('/convert', {
      method: 'POST',
      body: formData,
    });
  }

  async getJobStatus(fileName: string, jobId: string): Promise<JobMetadata> {
    const params = new URLSearchParams({
      file_name: fileName,
      job_id: jobId,
    });
    return this.request<JobMetadata>(`/jobStatus?${params.toString()}`);
  }

  async getQuestionnaires(fileName: string, jobId: string): Promise<QuestionnaireResponse> {
    const params = new URLSearchParams({
      file_name: fileName,
      job_id: jobId,
    });
    return this.request<QuestionnaireResponse>(`/questionnaires?${params.toString()}`);
  }

  async uploadQuestionnaires(
    fileName: string,
    jobId: string,
    questionnaires: unknown,
    failedScenarios: unknown
  ): Promise<string> {
    return this.request<string>('/questionnaires', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        file_name: fileName,
        job_id: jobId,
        questionnaires,
        failed_scenarios: failedScenarios,
      }),
    });
  }
}

export const fileServiceAPI = new FileServiceAPI();
