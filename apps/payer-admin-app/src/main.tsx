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

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { OxygenUIThemeProvider } from '@wso2/oxygen-ui';
import { customTheme } from './theme';
import './index.css';
import App from './App.tsx';

// Type declaration for window.config
declare global {
  interface Window {
    config?: {
      BFF_URL: string;
      PDEX_API_URL: string;
      QUESTIONNAIRE_GEN_API_URL: string;
    };
  }
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <OxygenUIThemeProvider theme={customTheme}>
      <App />
    </OxygenUIThemeProvider>
  </StrictMode>
);
