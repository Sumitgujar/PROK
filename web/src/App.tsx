import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import MainLayout from './layouts/MainLayout';
import { ProtectedRoute } from './components/ProtectedRoute';

function Placeholder({ title }: { title: string }) {
  return (
    <div style={{ padding: 32 }}>
      <h2>{title}</h2>
      <p style={{ color: '#888' }}>This module will be implemented in Stage 2.</p>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <MainLayout />
            </ProtectedRoute>
          }
        >
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="attendance" element={<Placeholder title="📋 Attendance" />} />
          <Route path="documents" element={<Placeholder title="📂 Documents" />} />
          <Route path="scholarships" element={<Placeholder title="🎓 Scholarships" />} />
          <Route path="courses" element={<Placeholder title="📚 Courses" />} />
          <Route path="analytics" element={<Placeholder title="📊 Analytics" />} />
        </Route>
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
