import { useCallback, useEffect, useMemo, useState } from "react"
import { adminApi } from "../services/admin"
import { downloadCsv } from "../utils/exportCsv"

interface ScholarshipApplication {
  _id: string
  scholarship_name: string
  student_name: string
  student_id?: string
  status: string
  applied_at: string
  missing_docs: string[]
  review_note?: string
}

const statusColor: Record<string, string> = {
  pending: "bg-amber-100 text-amber-800",
  approved: "bg-emerald-100 text-emerald-800",
  rejected: "bg-red-100 text-red-800",
}

export default function ScholarshipsPage() {
  const [apps, setApps] = useState<ScholarshipApplication[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState("")
  const [notice, setNotice] = useState("")
  const [filter, setFilter] = useState("all")
  const [search, setSearch] = useState("")
  const [reviewNote, setReviewNote] = useState("")
  const [actionId, setActionId] = useState("")
  const [busyId, setBusyId] = useState("")

  const load = useCallback(async (quiet = false) => {
    if (quiet) setRefreshing(true)
    else setLoading(true)
    setError("")
    try {
      const data = await adminApi.getScholarshipApplications()
      setApps(Array.isArray(data) ? data : data?.applications ?? [])
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load applications.")
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => { void load() }, [load])

  const counts = useMemo(() => ({
    all: apps.length,
    pending: apps.filter(a => a.status === "pending").length,
    approved: apps.filter(a => a.status === "approved").length,
    rejected: apps.filter(a => a.status === "rejected").length,
  }), [apps])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return apps.filter(a => (filter === "all" || a.status === filter) &&
      (!q || [a.scholarship_name, a.student_name, a.student_id ?? "", a.status, a.review_note ?? "", ...(a.missing_docs ?? [])].some(v => String(v).toLowerCase().includes(q))))
  }, [apps, filter, search])

  const handleReview = async (id: string, status: "approved" | "rejected") => {
    const app = apps.find(a => a._id === id)
    if (status === "rejected" && !reviewNote.trim() && !window.confirm("Reject this application without a review note?")) return
    setBusyId(id)
    setError("")
    setNotice("")
    try {
      await adminApi.reviewScholarshipApplication(id, status, reviewNote.trim())
      setReviewNote("")
      setActionId("")
      setNotice(`Application for “${app?.scholarship_name ?? "scholarship"}” marked ${status}.`)
      await load(true)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Application review failed.")
    } finally {
      setBusyId("")
    }
  }

  const exportApplications = () => downloadCsv("prok-scholarship-applications.csv", filtered.map(a => ({
    Scholarship: a.scholarship_name,
    Student: a.student_name,
    "Student ID": a.student_id ?? "",
    Status: a.status,
    "Applied At": a.applied_at ?? "",
    "Missing Documents": (a.missing_docs ?? []).join("; "),
    "Review Note": a.review_note ?? "",
  })))

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div><p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-600">Student financial support</p><h2 className="mt-1 text-3xl font-bold text-slate-900">Scholarship applications</h2><p className="mt-2 text-sm text-slate-500">Filter, search and review application decisions using the existing admin API.</p></div>
        <div className="mb-1 flex flex-wrap gap-2"><button onClick={exportApplications} disabled={!filtered.length} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export CSV</button><button onClick={() => void load(true)} disabled={refreshing} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">{refreshing ? "Refreshing…" : "↻ Refresh"}</button></div>
      </div>
      {notice && <div role="status" className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{notice}<button onClick={() => setNotice("")} className="float-right font-bold" aria-label="Dismiss message">×</button></div>}
      {error && <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"><span>{error}</span><button onClick={() => void load(true)} className="rounded-lg bg-red-700 px-3 py-1.5 font-semibold text-white hover:bg-red-800">Retry</button></div>}

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {(["all","pending","approved","rejected"] as const).map(f => <button key={f} onClick={() => setFilter(f)} aria-pressed={filter === f} className={"rounded-2xl border p-4 text-left transition " + (filter === f ? "border-blue-300 bg-blue-50 ring-2 ring-blue-100" : "border-slate-200 bg-white hover:border-slate-300")}>
          <span className="block text-xs font-bold uppercase tracking-wide text-slate-500">{f === "all" ? "All applications" : f}</span><span className="mt-1 block text-2xl font-bold tabular-nums text-slate-900">{counts[f]}</span>
        </button>)}
      </div>
      <label className="block max-w-xl text-xs font-bold uppercase tracking-wide text-slate-500">Search applications<input type="search" value={search} onChange={e => setSearch(e.target.value)} placeholder="Search scholarship, student, missing documents…" className="mt-1.5 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-normal normal-case outline-none focus:border-blue-400 focus:ring-4 focus:ring-blue-50" /></label>
      <div className="flex items-center justify-between text-sm text-slate-500"><span>Showing <strong className="text-slate-800">{filtered.length}</strong> of {apps.length} applications</span>{loading && <span>Loading…</span>}</div>

      {loading && apps.length === 0 ? <div className="flex h-44 items-center justify-center gap-3 text-sm text-slate-500"><span className="h-7 w-7 animate-spin rounded-full border-2 border-slate-200 border-t-blue-700" />Loading applications…</div>
      : filtered.length === 0 ? <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-16 text-center"><div className="text-4xl">🏆</div><p className="mt-3 font-semibold text-slate-800">No matching applications</p><p className="mt-1 text-sm text-slate-500">Try another filter or search phrase.</p><button onClick={() => {setFilter("all");setSearch("")}} className="mt-4 text-sm font-semibold text-blue-700">Clear filters</button></div>
      : <div className="space-y-3">{filtered.map(app => <article key={app._id} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md">
          <div className="flex flex-wrap items-start justify-between gap-3"><div><h3 className="font-bold text-slate-900">{app.scholarship_name || "Untitled scholarship"}</h3><p className="mt-1 text-sm text-slate-500">{app.student_name || app.student_id || "Unknown student"}</p><p className="mt-1 text-xs text-slate-400">Applied {app.applied_at?.slice(0,10) || "date unavailable"}</p></div><span className={"rounded-full px-3 py-1 text-xs font-bold capitalize " + (statusColor[app.status] ?? "bg-slate-100 text-slate-600")}>{app.status || "unknown"}</span></div>
          {(app.missing_docs?.length ?? 0) > 0 && <div className="mt-4 rounded-xl border border-red-100 bg-red-50 p-3"><p className="text-xs font-bold uppercase tracking-wide text-red-700">Missing documents</p><div className="mt-2 flex flex-wrap gap-2">{app.missing_docs.map(d => <span key={d} className="rounded-full bg-white px-2.5 py-1 text-xs font-medium text-red-700 ring-1 ring-red-200">{d}</span>)}</div></div>}
          {app.review_note && <div className="mt-3 rounded-xl bg-slate-50 px-3 py-2.5 text-sm text-slate-600"><span className="font-semibold">Review note:</span> {app.review_note}</div>}
          {app.status === "pending" && <div className="mt-4 border-t border-slate-100 pt-4">
            {actionId === app._id ? <div className="space-y-3"><label className="block text-xs font-semibold uppercase tracking-wide text-slate-500">Decision note <span className="font-normal normal-case">(recommended; required by your internal review policy if applicable)</span><textarea rows={2} value={reviewNote} onChange={e => setReviewNote(e.target.value)} placeholder="Add context for the decision…" className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm font-normal normal-case outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label><div className="flex flex-wrap gap-2"><button onClick={() => void handleReview(app._id,"approved")} disabled={busyId === app._id} className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 disabled:opacity-50">{busyId === app._id ? "Saving…" : "✓ Approve"}</button><button onClick={() => void handleReview(app._id,"rejected")} disabled={busyId === app._id} className="rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50">Reject</button><button onClick={() => {setActionId("");setReviewNote("")}} disabled={busyId === app._id} className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50">Cancel</button></div></div>
            : <button onClick={() => {setActionId(app._id);setReviewNote("");setError("")}} className="rounded-lg bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700 hover:bg-blue-100">Review application →</button>}
          </div>}
        </article>)}</div>}
    </div>
  )
}
