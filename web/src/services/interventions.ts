import { api } from "./api"

export interface InterventionInput {
  student_id: string
  issue: string
  recommendation: string
  action: string
  status?: string
  outcome?: string | null
}

export const interventions = {
  list: () => api.get("/interventions"),
  create: (data: InterventionInput) => api.post("/interventions/", data),
  get: (id: string) => api.get(`/interventions/${encodeURIComponent(id)}`),
  update: (id: string, data: Partial<InterventionInput>) => api.put(`/interventions/${encodeURIComponent(id)}`, data),
  updateStatus: (id: string, status: string) => api.patch(`/interventions/${encodeURIComponent(id)}/status`, { status }),
}
