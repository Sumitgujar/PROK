import { Outlet, NavLink, useNavigate } from "react-router-dom"
import { useAuth } from "../hooks/useAuth"

const NAV = [
  { to: "/dashboard", label: "Dashboard", emoji: "📊" },
  { to: "/overview", label: "Overview", emoji: "🎯" },
  { to: "/students", label: "Students", emoji: "🎓" },
  { to: "/attendance", label: "Attendance", emoji: "📋" },
  { to: "/documents", label: "Documents", emoji: "📄" },
  { to: "/scholarships", label: "Scholarships", emoji: "🏆" },
  { to: "/courses", label: "Courses", emoji: "📚" },
  { to: "/interventions", label: "Interventions", emoji: "🛡️" },
  { to: "/ai-insights", label: "AI Insights", emoji: "🤖" },
  { to: "/reports", label: "Reports", emoji: "📈" },
]

export default function MainLayout() {
  const { logout, user } = useAuth()
  const nav = useNavigate()
  const handleLogout = () => { logout(); nav("/login") }
  return (
    <div className="flex h-screen bg-gray-50">
      <aside className="w-64 bg-blue-900 text-white flex flex-col flex-shrink-0">
        <div className="p-6 border-b border-blue-800">
          <div className="text-2xl font-bold tracking-tight">PROK Admin</div>
          <div className="text-blue-300 text-sm mt-1">{user?.full_name || user?.name || "Admin"}</div>
        </div>
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {NAV.map(n => (
            <NavLink key={n.to} to={n.to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition ${
                  isActive ? "bg-blue-700 text-white shadow-sm" : "text-blue-200 hover:bg-blue-800 hover:text-white"}`}>
              <span className="text-base">{n.emoji}</span><span>{n.label}</span>
            </NavLink>
          ))}
        </nav>
        <button onClick={handleLogout}
          className="m-4 p-3 text-sm font-medium text-blue-300 hover:text-white hover:bg-blue-800 rounded-lg text-left transition flex items-center gap-2">
          <span>🚪</span> Sign Out
        </button>
      </aside>
      <main className="flex-1 overflow-auto p-8">
        <Outlet />
      </main>
    </div>
  )
}
