import { api } from "./api"
export const attendanceApi = {
  getTodaySessions: () => api.get("/attendance/sessions/today"),
  getSessionRecords: (id: string) => api.get(`/attendance/sessions/${id}/records`),
  getCourseHistory: (id: string) => api.get(`/attendance/courses/${id}/history`),
}
