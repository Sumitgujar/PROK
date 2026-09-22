import { api } from './api';
export const interventions = {
  list: () => api.get('/interventions'),
  updateStatus: (id: string, status: string) => api.patch(`/interventions/${id}/status`, { status }),
};
