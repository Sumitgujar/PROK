import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom"
import { useAuth } from "./hooks/useAuth"
import LoginPage from "./pages/LoginPage"
import DashboardPage from "./pages/DashboardPage"
import StudentsPage from "./pages/StudentsPage"
import AttendancePage from "./pages/AttendancePage"
import DocumentsPage from "./pages/DocumentsPage"
import ScholarshipsPage from "./pages/ScholarshipsPage"
import CoursesPage from "./pages/CoursesPage"
import MainLayout from "./layouts/MainLayout"

function Protected({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuth()
  return isAuthenticated ? <>{children}</> : <Navigate to="/login" replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={<Protected><MainLayout /></Protected>}>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="students" element={<StudentsPage />} />
          <Route path="attendance" element={<AttendancePage />} />
          <Route path="documents" element={<DocumentsPage />} />
          <Route path="scholarships" element={<ScholarshipsPage />} />
          <Route path="courses" element={<CoursesPage />} />
        </Route>
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
