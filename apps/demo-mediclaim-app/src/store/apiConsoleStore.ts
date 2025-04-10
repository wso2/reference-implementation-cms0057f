
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
