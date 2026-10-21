import { api } from "./api"

export interface StudentCreateInput {
  full_name: string
  email: string
  college_id: string
  password?: string
  department?: string
  semester?: number
  year?: number
  cgpa?: number
}

export const adminApi = {
  getStats: () => api.get("/admin/stats"),
  getStudents: () => api.get("/admin/students"),
  createStudent: (data: StudentCreateInput) => api.post("/admin/students", data),
  deleteStudent: (id: string) => api.delete(`/admin/students/${encodeURIComponent(id)}`),
  getDocuments: () => api.get("/admin/documents"),
  verifyDocument: (id: string, note?: string) => api.post(`/admin/documents/${id}/verify`, { review_note: note }),
  rejectDocument: (id: string, note?: string) => api.post(`/admin/documents/${id}/reject`, { review_note: note }),
  getScholarshipApplications: () => api.get("/admin/scholarship-applications"),
  reviewScholarshipApplication: (id: string, status: string, note?: string) =>
    api.post(`/admin/scholarship-applications/${id}/review`, { status, review_note: note }),
}
