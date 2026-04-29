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

const API_BASE_URL = window.config?.BFF_URL || 'http://localhost:6091/v1';

export type TimeFilter =
  | 'PAST_10_MIN'
  | 'PAST_30_MIN'
  | 'PAST_1_HOUR'
  | 'PAST_2_HOURS'
  | 'PAST_12_HOURS'
  | 'PAST_24_HOURS';

export interface LogsResponse {
  logs: unknown[];
  totalCount: number;
  timeFilter?: string;
  keyword?: string;
}

export interface ErrorPayload {
  timestamp: string;
  status: number;
  reason: string;
  message: string;
  path: string;
  method: string;
}

class LogsAPI {
  private async request<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const error: ErrorPayload = await response.json().catch(() => ({
        timestamp: new Date().toISOString(),
        status: response.status,
        reason: response.statusText,
        message: 'An error occurred',
        path: endpoint,
        method: 'GET',
      }));
      throw error;
    }

    return response.json();
  }

  async queryLogs(params?: {
    timeFilter?: TimeFilter;
    keyword?: string;
  }): Promise<LogsResponse> {
    const queryParams = new URLSearchParams();

    if (params?.timeFilter) {
      queryParams.append('timeFilter', params.timeFilter);
    }

    if (params?.keyword && params.keyword.trim()) {
      queryParams.append('keyword', params.keyword.trim());
    }

    const query = queryParams.toString();
    return this.request<LogsResponse>(`/logs${query ? `?${query}` : ''}`);
  }
}

export const logsAPI = new LogsAPI();
