import { useState, useCallback } from "react"
import { api } from "../services/api"

const TOKEN_KEY = "prok_token"
const USER_KEY = "prok_user"

export function useAuth() {
  const [isAuthenticated, setAuthenticated] = useState(() => !!localStorage.getItem(TOKEN_KEY))
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem(USER_KEY) || "null") } catch { return null }
  })

  const login = useCallback(async (email: string, password: string) => {
    const data = await api.post("/auth/login", { email, password }, false)
    if (data.user?.role !== "admin") throw new Error("Admin access only")
    localStorage.setItem(TOKEN_KEY, data.access_token)
    localStorage.setItem(USER_KEY, JSON.stringify(data.user))
    setAuthenticated(true)
    setUser(data.user)
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
    setAuthenticated(false)
    setUser(null)
  }, [])

  return { isAuthenticated, user, login, logout }
}
