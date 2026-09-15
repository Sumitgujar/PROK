import { api } from "./api"
export const coursesApi = {
  getCourses: () => api.get("/courses/"),
}
