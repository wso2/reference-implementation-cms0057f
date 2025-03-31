import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import 'bootstrap/dist/css/bootstrap.min.css'; // Import Bootstrap styles globally
import 'react-datepicker/dist/react-datepicker.css'; // Import React Datepicker styles globally
import App from './App.tsx';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
