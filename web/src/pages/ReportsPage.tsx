import { useCallback, useEffect, useState } from "react"
import { api } from "../services/api"
import { downloadCsv } from "../utils/exportCsv"
import { PageHeader, LoadingSpinner, ErrorMessage, PageShell, Card } from "../components/ui"

interface Stats {
  total_students?: number
  total_courses?: number
  total_documents?: number
  pending_documents?: number
  total_scholarships?: number
  pending_scholarship_applications?: number
}

export function ReportsPage() {
  const [data, setData] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState("")

  const load = useCallback(async (quiet = false) => {
    if (quiet) setRefreshing(true)
    else setLoading(true)
    setError("")
    try {
      const response = await api.get("/admin/stats")
      setData(response?.data ?? response)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load report data.")
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => { void load() }, [load])

  const metrics = [
    { label: "Students", key: "total_students", color: "bg-blue-600" },
    { label: "Courses", key: "total_courses", color: "bg-emerald-600" },
    { label: "Documents", key: "total_documents", color: "bg-violet-600" },
    { label: "Pending documents", key: "pending_documents", color: "bg-amber-500" },
    { label: "Scholarships", key: "total_scholarships", color: "bg-pink-600" },
    { label: "Pending applications", key: "pending_scholarship_applications", color: "bg-orange-600" },
  ] as const

  const exportReport = () => {
    if (!data) return
    downloadCsv(`prok-platform-report-${new Date().toISOString().slice(0,10)}.csv`, [
      { Metric: "Total students", Value: data.total_students ?? 0 },
      { Metric: "Total courses", Value: data.total_courses ?? 0 },
      { Metric: "Total documents", Value: data.total_documents ?? 0 },
      { Metric: "Pending documents", Value: data.pending_documents ?? 0 },
      { Metric: "Total scholarships", Value: data.total_scholarships ?? 0 },
      { Metric: "Pending scholarship applications", Value: data.pending_scholarship_applications ?? 0 },
      { Metric: "Generated at", Value: new Date().toLocaleString() },
    ])
  }

  if (loading) return <LoadingSpinner message="Loading live report data…" />
  if (error && !data) return <PageShell><PageHeader title="Reports" sub="Platform counts from the live API" /><ErrorMessage message={error} onRetry={() => void load()} /></PageShell>
  if (!data) return null

  const max = Math.max(1, ...metrics.map(m => Number(data[m.key] ?? 0)))

  return (
    <PageShell>
      <div className="flex flex-wrap items-end justify-between gap-3">
        <PageHeader title="Reports" sub="Exportable operational counts from the PROK backend." />
        <div className="mb-6 flex gap-2">
          <button onClick={exportReport} className="rounded-xl bg-blue-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-800">↓ Export CSV</button>
          <button onClick={() => void load(true)} disabled={refreshing} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50">{refreshing ? "Refreshing…" : "↻ Refresh"}</button>
        </div>
      </div>
      {error && <div role="status" className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">Refresh failed. Showing last loaded values: {error}</div>}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {metrics.map(m => <div key={m.key} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-xs font-bold uppercase tracking-wider text-slate-500">{m.label}</p>
          <p className="mt-2 text-3xl font-bold tabular-nums text-slate-900">{Number(data[m.key] ?? 0).toLocaleString()}</p>
          <div className="mt-4 h-2 overflow-hidden rounded-full bg-slate-100"><div className={`h-full rounded-full ${m.color}`} style={{ width: `${Math.max(0, Number(data[m.key] ?? 0)) / max * 100}%` }} /></div>
          <p className="mt-2 text-xs text-slate-400">Relative to the largest count shown</p>
        </div>)}
      </div>
      <Card className="mt-6">
        <h3 className="text-base font-bold text-slate-900">Record distribution</h3>
        <p className="mt-1 text-sm text-slate-500">Bars compare the counts returned by <code>/admin/stats</code>; they are not percentages of student performance.</p>
        <div className="mt-5 space-y-4">
          {metrics.map(m => {
            const value = Number(data[m.key] ?? 0)
            return <div key={m.key} className="grid grid-cols-[minmax(120px,190px)_minmax(0,1fr)_60px] items-center gap-3">
              <span className="truncate text-sm font-medium text-slate-600">{m.label}</span>
              <div className="h-3 overflow-hidden rounded-full bg-slate-100"><div className={`h-full rounded-full transition-all duration-500 ${m.color}`} style={{ width: `${Math.max(0, value) / max * 100}%` }} /></div>
              <span className="text-right text-sm font-bold tabular-nums text-slate-800">{value.toLocaleString()}</span>
            </div>
          })}
        </div>
      </Card>
      <p className="text-xs text-slate-400">Report values are read from the backend when this page loads or refreshes. Attendance averages and risk totals are omitted because the current admin stats endpoint does not return them.</p>
    </PageShell>
  )
}
