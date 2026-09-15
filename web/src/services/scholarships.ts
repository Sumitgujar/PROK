import { api } from "./api"
export const scholarshipsApi = {
  getAll: () => api.get("/scholarships/"),
  getApplications: () => api.get("/scholarships/applications"),
}
