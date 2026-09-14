import { Navigate } from 'react-router-dom';
import type { UserRole } from '../types';

interface Props {
  children: React.ReactNode;
  allowedRoles?: UserRole[];
}

export function ProtectedRoute({ children, allowedRoles }: Props) {
  const token = localStorage.getItem('prok_token');
  const rawUser = localStorage.getItem('prok_user');

  if (!token || !rawUser) return <Navigate to="/login" replace />;

  if (allowedRoles) {
    try {
      const user = JSON.parse(rawUser);
      if (!allowedRoles.includes(user.role)) {
        return <Navigate to="/dashboard" replace />;
      }
    } catch {
      return <Navigate to="/login" replace />;
    }
  }

  return <>{children}</>;
}
