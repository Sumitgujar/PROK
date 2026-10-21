import { api } from "./api"

export interface CourseCreateInput {
  title: string
  course_code: string
  department: string
  credits: number
  description?: string
  tags?: string[]
}

export const coursesApi = {
  getCourses: () => api.get("/courses/"),
  createCourse: (data: CourseCreateInput) => api.post("/courses/", data),
  deleteCourse: (id: string) => api.delete(`/courses/${encodeURIComponent(id)}`),
}
