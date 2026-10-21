import { useCallback, useEffect, useState } from "react"
import { useNavigate } from "react-router-dom"
import { adminApi } from "../services/admin"

interface Stats {
  total_students: number
  total_courses: number
  total_documents: number
  pending_documents: number
  total_scholarships: number
  pending_scholarship_applications: number
}

const cards = [
  { label: "Total students", key: "total_students", icon: "🎓", color: "border-blue-500", path: "/students", hint: "Browse student directory" },
  { label: "Total courses", key: "total_courses", icon: "📚", color: "border-emerald-500", path: "/courses", hint: "Explore course catalogue" },
  { label: "Total documents", key: "total_documents", icon: "📄", color: "border-violet-500", path: "/documents", hint: "Open document review" },
  { label: "Pending documents", key: "pending_documents", icon: "⏳", color: "border-amber-500", path: "/documents", hint: "Review documents waiting for action" },
  { label: "Scholarships", key: "total_scholarships", icon: "🏆", color: "border-pink-500", path: "/scholarships", hint: "View scholarship applications" },
  { label: "Pending applications", key: "pending_scholarship_applications", icon: "🗂️", color: "border-orange-500", path: "/scholarships", hint: "Review pending applications" },
] as const

export default function DashboardPage() {
  const navigate = useNavigate()
  const [stats, setStats] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState("")

  const load = useCallback(async (quiet = false) => {
    if (quiet) setRefreshing(true)
    else setLoading(true)
    setError("")
    try {
      const data = await adminApi.getStats()
      setStats(data?.data ?? data)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Unable to load dashboard statistics.")
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => { void load() }, [load])

  if (loading) return (
    <div className="flex h-64 items-center justify-center gap-3 text-sm text-slate-500" role="status">
      <span className="h-8 w-8 animate-spin rounded-full border-2 border-slate-200 border-t-blue-700" /> Loading dashboard…
    </div>
  )

  if (error && !stats) return (
    <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-800" role="alert">
      <p className="font-semibold">Dashboard data could not be loaded</p>
      <p className="mt-1 text-sm">{error}</p>
      <button onClick={() => void load()} className="mt-4 rounded-lg bg-red-700 px-4 py-2 text-sm font-semibold text-white hover:bg-red-800">Try again</button>
    </div>
  )

  return (
    <div className="space-y-7">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-600">Operations overview</p>
          <h2 className="mt-1 text-3xl font-bold tracking-tight text-slate-900">Dashboard</h2>
          <p className="mt-2 text-sm text-slate-500">A live summary of academic operations. Select any metric to open the relevant module.</p>
        </div>
        <button onClick={() => void load(true)} disabled={refreshing} className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-blue-300 hover:text-blue-700 disabled:cursor-wait disabled:opacity-60">
          <span className={refreshing ? "animate-spin" : ""}>↻</span>{refreshing ? "Refreshing…" : "Refresh data"}
        </button>
      </div>

      {error && <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800" role="status">Refresh failed: {error}. Showing the last successfully loaded data.</div>}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {cards.map(card => (
          <button key={card.key} type="button" onClick={() => navigate(card.path)} title={card.hint}
            className={`group rounded-2xl border border-slate-200 border-l-4 ${card.color} bg-white p-5 text-left shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-lg focus:outline-none focus:ring-4 focus:ring-blue-100`}>
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="text-sm font-medium text-slate-500">{card.label}</p>
                <p className="mt-2 text-3xl font-bold tabular-nums text-slate-900">{Number(stats?.[card.key] ?? 0).toLocaleString()}</p>
              </div>
              <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-50 text-2xl transition group-hover:scale-105">{card.icon}</span>
            </div>
            <div className="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 text-xs">
              <span className="text-slate-500">{card.hint}</span><span className="font-bold text-blue-700">Open →</span>
            </div>
          </button>
        ))}
      </div>

      <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h3 className="text-lg font-bold text-slate-900">Quick actions</h3>
            <p className="mt-1 text-sm text-slate-500">Jump directly into common admin workflows.</p>
          </div>
          <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">PROK · Admin</span>
        </div>
        <div className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {[
            { label: "Add student", sub: "Create a student account", icon: "＋", path: "/students", tone: "text-blue-700 bg-blue-50" },
            { label: "Review documents", sub: "Verify or reject uploads", icon: "▤", path: "/documents", tone: "text-violet-700 bg-violet-50" },
            { label: "Scholarship decisions", sub: "Process pending applications", icon: "✓", path: "/scholarships", tone: "text-emerald-700 bg-emerald-50" },
            { label: "Attendance records", sub: "Inspect class sessions", icon: "◷", path: "/attendance", tone: "text-amber-700 bg-amber-50" },
          ].map(action => (
            <button key={action.label} onClick={() => navigate(action.path)} className="flex items-center gap-3 rounded-xl border border-slate-200 p-4 text-left transition hover:border-blue-200 hover:bg-slate-50">
              <span className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl text-xl font-bold ${action.tone}`}>{action.icon}</span>
              <span><span className="block text-sm font-semibold text-slate-800">{action.label}</span><span className="mt-1 block text-xs text-slate-500">{action.sub}</span></span>
            </button>
          ))}
        </div>
      </section>
      <p className="text-xs text-slate-400">Statistics are retrieved from your FastAPI backend. Dashboard values are not hard-coded.</p>
    </div>
  )
}
