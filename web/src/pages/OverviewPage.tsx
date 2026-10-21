import { useCallback, useEffect, useState } from "react"
import { Link } from "react-router-dom"
import { api } from "../services/api"
import { Card, PageHeader, LoadingSpinner, ErrorMessage, PageShell } from "../components/ui"

interface Stats {
  total_students?: number
  total_courses?: number
  total_documents?: number
  pending_documents?: number
  total_scholarships?: number
  pending_scholarship_applications?: number
}

const metricCards = [
  { label: "Students", key: "total_students", route: "/students", color: "#1D4ED8", icon: "🎓" },
  { label: "Courses", key: "total_courses", route: "/courses", color: "#059669", icon: "📚" },
  { label: "Documents", key: "total_documents", route: "/documents", color: "#7C3AED", icon: "📄" },
  { label: "Pending documents", key: "pending_documents", route: "/documents", color: "#D97706", icon: "⏳" },
  { label: "Scholarships", key: "total_scholarships", route: "/scholarships", color: "#DB2777", icon: "🏆" },
  { label: "Pending applications", key: "pending_scholarship_applications", route: "/scholarships", color: "#EA580C", icon: "🗂️" },
] as const

export function OverviewPage() {
  const [data, setData] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")

  const load = useCallback(async () => {
    setLoading(true); setError("")
    try {
      const response = await api.get("/admin/stats")
      setData(response?.data ?? response)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load the overview.")
    } finally { setLoading(false) }
  }, [])

  useEffect(() => { void load() }, [load])
  if (loading) return <LoadingSpinner message="Loading overview…" />
  if (error) return <PageShell><PageHeader title="Overview" sub="Platform-wide summary" /><ErrorMessage message={error} onRetry={() => void load()} /></PageShell>
  if (!data) return null

  return (
    <PageShell>
      <PageHeader title="Overview" sub="Platform-wide summary from the live admin stats endpoint." />
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {metricCards.map(metric => <Link key={metric.key} to={metric.route} className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-blue-200 hover:shadow-md focus:outline-none focus:ring-4 focus:ring-blue-100">
          <div className="flex items-start justify-between"><div><p className="text-sm font-medium text-slate-500">{metric.label}</p><p className="mt-2 text-3xl font-bold tabular-nums text-slate-900">{Number(data[metric.key] ?? 0).toLocaleString()}</p></div><span className="rounded-xl bg-slate-50 p-3 text-2xl">{metric.icon}</span></div>
          <div className="mt-4 flex items-center justify-between border-t border-slate-100 pt-3 text-xs"><span className="text-slate-400">Open related module</span><span className="font-semibold text-blue-700">View details →</span></div>
        </Link>)}
      </div>
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
        <Card>
          <h3 className="text-base font-bold text-slate-900">PROK operating principles</h3>
          <p className="mt-1 text-sm text-slate-500">The product is designed to support academic teams with transparent, human-reviewed workflows.</p>
          <div className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-2">
            {[["01","MANAGE","Organize academic records and processes"],["02","GUIDE","Surface useful guidance from available data"],["03","SUPPORT","Coordinate student support workflows"],["04","GROW","Help teams track progress and follow-up"]].map(([n,title,description]) => <div key={title} className="rounded-xl border border-slate-100 bg-slate-50 p-4"><span className="text-xs font-bold text-blue-600">{n}</span><p className="mt-1 font-bold text-slate-900">{title}</p><p className="mt-1 text-xs leading-5 text-slate-500">{description}</p></div>)}
          </div>
        </Card>
        <Card>
          <h3 className="text-base font-bold text-slate-900">Quick actions</h3>
          <p className="mt-1 text-sm text-slate-500">Continue a common administrative workflow.</p>
          <div className="mt-5 space-y-2">
            {[["Review pending documents","View uploads waiting for review","/documents","📄"],["Process scholarship applications","Review student funding decisions","/scholarships","🏆"],["Manage student support","Create or resolve an intervention","/interventions","🛡️"],["Explore risk insights","Inspect student risk indicators","/ai-insights","🤖"]].map(([title,description,to,icon]) => <Link key={to} to={to} className="flex items-center gap-3 rounded-xl border border-slate-200 p-3 transition hover:border-blue-200 hover:bg-blue-50/50"><span className="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-100 text-xl">{icon}</span><span className="min-w-0 flex-1"><span className="block text-sm font-semibold text-slate-800">{title}</span><span className="mt-0.5 block text-xs text-slate-500">{description}</span></span><span className="text-blue-700">→</span></Link>)}
          </div>
          <button onClick={() => void load()} className="mt-4 rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50">↻ Refresh overview</button>
        </Card>
      </div>
      <p className="text-xs text-slate-400">Only fields returned by the current API are shown. Attendance averages, risk totals and teacher totals are not available from this endpoint and are not fabricated here.</p>
    </PageShell>
  )
}
