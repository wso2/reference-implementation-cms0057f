import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './components/AuthProvider';
import MainLayout from './layouts/MainLayout';
import PARequests from './pages/PARequests';
import PARequestDetail from './pages/PARequestDetail';
import PayerDataExchange from './pages/PayerDataExchange';
import PayerDataExchangeDetail from './pages/PayerDataExchangeDetail';
import Questionnaires from './pages/Questionnaires';
import QuestionnaireDetail from './pages/QuestionnaireDetail';
import Payers from './pages/Payers';
import PayerDetail from './pages/PayerDetail';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<MainLayout />}>
            <Route index element={<Navigate to="/pa-requests" replace />} />
            <Route path="pa-requests" element={<PARequests />} />
            <Route path="pa-requests/processed" element={<PARequests />} />
            <Route path="pa-requests/processed/:requestId" element={<PARequestDetail />} />
            <Route path="pa-requests/:requestId" element={<PARequestDetail />} />
            <Route path="payer-data-exchange" element={<PayerDataExchange />} />
            <Route path="payer-data-exchange/:exchangeId" element={<PayerDataExchangeDetail />} />
            <Route path="questionnaires" element={<Questionnaires />} />
            <Route path="questionnaires/:questionnaireId" element={<QuestionnaireDetail />} />
            <Route path="manage/payers" element={<Payers />} />
            <Route path="manage/payers/:payerId" element={<PayerDetail />} />
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
