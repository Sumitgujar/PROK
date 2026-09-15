import axios from "axios"

const BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:8000"

const client = axios.create({ baseURL: BASE_URL })

client.interceptors.request.use(config => {
  const token = localStorage.getItem("prok_token")
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

client.interceptors.response.use(
  r => r,
  err => {
    if (err.response?.status === 401) {
      localStorage.removeItem("prok_token")
      window.location.href = "/login"
    }
    const detail = err.response?.data?.detail || err.message
    return Promise.reject(new Error(Array.isArray(detail) ? detail[0]?.msg : detail))
  }
)

export const api = {
  get: (path: string) => client.get(path).then(r => r.data),
  post: (path: string, body: unknown, auth = true) => {
    if (!auth) {
      return axios.post(`${BASE_URL}${path}`, body).then(r => r.data)
          .catch(e => Promise.reject(new Error(e.response?.data?.detail || e.message)))
    }
    return client.post(path, body).then(r => r.data)
  },
  put: (path: string, body: unknown) => client.put(path, body).then(r => r.data),
}
