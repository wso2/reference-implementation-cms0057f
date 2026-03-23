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
