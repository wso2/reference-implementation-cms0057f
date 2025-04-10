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

import { v4 as uuidv4 } from 'uuid';
import { useApiConsoleStore, ApiRequest, ApiResponse } from '../store/apiConsoleStore';

// Original fetch function
const originalFetch = window.fetch;

// Intercept all fetch requests
export const setupApiInterceptor = () => {
  window.fetch = async function(input: RequestInfo | URL, init?: RequestInit) {
    const requestId = uuidv4();
    const requestTimestamp = new Date();
    
    let method = 'GET';
    let url = '';
    
    if (typeof input === 'string') {
      url = input;
    } else if (input instanceof URL) {
      url = input.toString();
    } else if (input instanceof Request) {
      url = input.url;
      method = input.method;
    }
    
    if (init?.method) {
      method = init.method;
    }
    
    // Capture request
    const requestBody = init?.body ? JSON.parse(init.body.toString()) : undefined;
    const requestHeaders = init?.headers ? Object.fromEntries(new Headers(init.headers).entries()) : {};
    
    const request: ApiRequest = {
      id: requestId,
      timestamp: requestTimestamp,
      url,
      method,
      body: requestBody,
      headers: requestHeaders
    };
    
    useApiConsoleStore.getState().addRequest(request);
    
    try {
      // Make the original request
      const response = await originalFetch(input, init);
      
      // Clone the response to avoid consuming it
      const clonedResponse = response.clone();
      
      // Parse response data
      let responseData;
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('application/json')) {
        responseData = await clonedResponse.json();
      } else {
        responseData = await clonedResponse.text();
      }
      
      // Capture response
      const apiResponse: ApiResponse = {
        id: uuidv4(),
        requestId,
        timestamp: new Date(),
        status: response.status,
        statusText: response.statusText,
        data: responseData,
        headers: Object.fromEntries(response.headers.entries())
      };
      
      useApiConsoleStore.getState().addResponse(apiResponse);
      
      return response;
    } catch (error) {
      // Capture error response
      const apiResponse: ApiResponse = {
        id: uuidv4(),
        requestId,
        timestamp: new Date(),
        status: 0,
        statusText: error instanceof Error ? error.message : String(error),
        data: { error: error instanceof Error ? error.message : String(error) }
      };
      
      useApiConsoleStore.getState().addResponse(apiResponse);
      
      throw error;
    }
  };
};

// Function to restore original fetch
export const tearDownApiInterceptor = () => {
  window.fetch = originalFetch;
};
