import { api } from "./api"
export const documentsApi = {
  getAll: () => api.get("/documents/all"),
}
