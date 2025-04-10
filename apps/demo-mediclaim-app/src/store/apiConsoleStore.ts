// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
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

// Store for the API Console
import { create } from 'zustand';

export interface ApiRequest {
  id: string;
  timestamp: Date;
  url: string;
  method: string;
  body?: any;
  headers?: Record<string, string>;
}

export interface ApiResponse {
  id: string;
  requestId: string;
  timestamp: Date;
  status: number;
  statusText: string;
  data?: any;
  headers?: Record<string, string>;
}

interface ApiConsoleState {
  isOpen: boolean;
  requests: ApiRequest[];
  responses: ApiResponse[];
  setIsOpen: (isOpen: boolean) => void;
  addRequest: (request: ApiRequest) => void;
  addResponse: (response: ApiResponse) => void;
  clearLogs: () => void;
}

export const useApiConsoleStore = create<ApiConsoleState>((set) => ({
  isOpen: false,
  requests: [],
  responses: [],
  setIsOpen: (isOpen) => set({ isOpen }),
  addRequest: (request) => 
    set((state) => ({ 
      requests: [request, ...state.requests].slice(0, 50) // Keep last 50 requests
    })),
  addResponse: (response) => 
    set((state) => ({ 
      responses: [response, ...state.responses].slice(0, 50) // Keep last 50 responses
    })),
  clearLogs: () => set({ requests: [], responses: [] }),
}));
