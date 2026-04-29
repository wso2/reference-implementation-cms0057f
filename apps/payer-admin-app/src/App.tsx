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
import Logs from './pages/Logs';

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
            <Route path="logs" element={<Logs />} />
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
