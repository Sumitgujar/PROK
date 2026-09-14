import { useState, useCallback } from 'react';
import { authApi } from '../services/api';
import type { User } from '../types';

function getStoredUser(): User | null {
  try {
    const raw = localStorage.getItem('prok_user');
    return raw ? (JSON.parse(raw) as User) : null;
  } catch {
    return null;
  }
}

export function useAuth() {
  const [user, setUser] = useState<User | null>(getStoredUser);

  const login = useCallback(async (email: string, password: string) => {
    const res = await authApi.login(email, password);
    localStorage.setItem('prok_token', res.access_token);
    localStorage.setItem('prok_user', JSON.stringify(res.user));
    setUser(res.user);
    return res.user;
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('prok_token');
    localStorage.removeItem('prok_user');
    setUser(null);
  }, []);

  return { user, login, logout, isAuthenticated: !!user };
}
