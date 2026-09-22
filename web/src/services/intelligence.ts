import { api } from './api';
export const intelligence = {
  adminOverview: () => api.get('/intelligence/admin/overview'),
  studentRisk: (studentId: string) => api.get(`/intelligence/attendance/${studentId}/risk`),
};
