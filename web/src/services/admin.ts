import { api } from "./api"

export const adminApi = {
  getStats: () => api.get("/admin/stats"),
  getStudents: () => api.get("/admin/students"),
  getDocuments: () => api.get("/admin/documents"),
  verifyDocument: (id: string, note?: string) => api.post(`/admin/documents/${id}/verify`, { review_note: note }),
  rejectDocument: (id: string, note?: string) => api.post(`/admin/documents/${id}/reject`, { review_note: note }),
  getScholarshipApplications: () => api.get("/admin/scholarship-applications"),
  reviewScholarshipApplication: (id: string, status: string, note?: string) =>
    api.post(`/admin/scholarship-applications/${id}/review`, { status, review_note: note }),
}
