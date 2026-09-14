import axios from 'axios';
import type { TokenResponse, User } from '../types';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000';

export const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Attach JWT to every request when available
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('prok_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Auto-logout on 401
api.interceptors.response.use(
  (r) => r,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('prok_token');
      localStorage.removeItem('prok_user');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  },
);

// ---------- Auth ----------
export const authApi = {
  register: (payload: {
    name: string;
    email: string;
    password: string;
    role?: string;
    college_id?: string;
  }): Promise<TokenResponse> =>
    api.post('/auth/register', payload).then((r) => r.data),

  // OAuth2 login expects form-data (username + password)
  login: (email: string, password: string): Promise<TokenResponse> => {
    const form = new URLSearchParams();
    form.append('username', email);
    form.append('password', password);
    return api
      .post('/auth/login', form, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      })
      .then((r) => r.data);
  },

  me: (): Promise<User> => api.get('/auth/me').then((r) => r.data),
};

// ---------- Health ----------
export const healthApi = {
  check: () => api.get('/health').then((r) => r.data),
};
