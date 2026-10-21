import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react"
import { useNavigate } from "react-router-dom"
import { api } from "../services/api"
import { interventions, type InterventionInput } from "../services/interventions"
import { adminApi } from "../services/admin"
import { downloadCsv } from "../utils/exportCsv"
import { PageHeader, LoadingSpinner, ErrorMessage, EmptyState, Badge, PageShell, StatCard } from "../components/ui"

interface Intervention {
  _id: string
  student_id?: string
  student_name?: string
  issue?: string
  reason?: string
  intervention_type?: string
  recommendation?: string
  action?: string
  status: string
  outcome?: string
  timestamp?: string
  created_at?: string
}

interface StudentChoice { college_id: string; full_name?: string; name?: string; email?: string }

const blankForm = { student_id: "", issue: "", recommendation: "", action: "", status: "OPEN", outcome: "" }

export function InterventionsPage() {
  const [items, setItems] = useState<Intervention[]>([])
  const [students, setStudents] = useState<StudentChoice[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState("")
  const [notice, setNotice] = useState("")
  const [filter, setFilter] = useState("ALL")
  const [search, setSearch] = useState("")
  const [saving, setSaving] = useState(false)
  const [updating, setUpdating] = useState<string | null>(null)
  const [formOpen, setFormOpen] = useState(false)
  const [editing, setEditing] = useState<Intervention | null>(null)
  const [form, setForm] = useState(blankForm)
  const navigate = useNavigate()

  const load = useCallback(async (quiet = false) => {
    if (quiet) setRefreshing(true)
    else setLoading(true)
    setError("")
    try {
      const data = await interventions.list()
      setItems(Array.isArray(data) ? data : data?.interventions ?? [])
      try {
        const studentData = await adminApi.getStudents()
        setStudents(Array.isArray(studentData) ? studentData : studentData?.students ?? [])
      } catch {
        // The intervention list remains usable if directory lookup fails.
        setStudents([])
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load interventions.")
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => { void load() }, [load])

  const studentNames = useMemo(() => new Map(students.map(s => [s.college_id, s.full_name || s.name || s.college_id])), [students])
  const counts = useMemo(() => ({
    OPEN: items.filter(i => i.status === "OPEN").length,
    IN_PROGRESS: items.filter(i => i.status === "IN_PROGRESS").length,
    RESOLVED: items.filter(i => i.status === "RESOLVED").length,
  }), [items])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return items.filter(item => (filter === "ALL" || item.status === filter) &&
      (!q || [item.student_name ?? "", item.student_id ?? "", studentNames.get(item.student_id ?? "") ?? "", item.issue ?? "", item.reason ?? "", item.recommendation ?? "", item.action ?? "", item.status, item.outcome ?? ""].some(v => v.toLowerCase().includes(q))))
  }, [items, filter, search, studentNames])

  const beginCreate = () => {
    setEditing(null)
    setForm(blankForm)
    setFormOpen(true)
    setError("")
    setNotice("")
  }

  const beginEdit = (item: Intervention) => {
    setEditing(item)
    setForm({
      student_id: item.student_id ?? "",
      issue: item.issue ?? item.reason ?? item.intervention_type ?? "",
      recommendation: item.recommendation ?? "",
      action: item.action ?? "",
      status: item.status ?? "OPEN",
      outcome: item.outcome ?? "",
    })
    setFormOpen(true)
    setError("")
    setNotice("")
  }

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaving(true); setError(""); setNotice("")
    try {
      if (editing) {
        await interventions.update(editing._id, {
          issue: form.issue.trim(),
          recommendation: form.recommendation.trim(),
          action: form.action.trim(),
          outcome: form.outcome.trim() || null,
          status: form.status,
        })
        setNotice("Intervention updated.")
      } else {
        const payload: InterventionInput = {
          student_id: form.student_id.trim(),
          issue: form.issue.trim(),
          recommendation: form.recommendation.trim(),
          action: form.action.trim(),
          status: form.status,
          outcome: form.outcome.trim() || undefined,
        }
        await interventions.create(payload)
        setNotice("Intervention created and saved.")
      }
      setFormOpen(false)
      setEditing(null)
      setForm(blankForm)
      await load(true)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Intervention could not be saved.")
    } finally { setSaving(false) }
  }

  const updateStatus = async (id: string, status: string) => {
    const label = status.replace("_", " ").toLowerCase()
    if (!window.confirm(`Move this intervention to “${label}”?`)) return
    setUpdating(id); setError(""); setNotice("")
    try {
      await interventions.updateStatus(id, status)
      setItems(current => current.map(item => item._id === id ? { ...item, status } : item))
      setNotice(`Intervention status changed to ${label}.`)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Status update failed.")
    } finally { setUpdating(null) }
  }

  const exportItems = () => downloadCsv("prok-interventions.csv", filtered.map(item => ({
    Student: item.student_name || studentNames.get(item.student_id ?? "") || item.student_id || "",
    "Student ID": item.student_id ?? "",
    Issue: item.issue ?? item.reason ?? item.intervention_type ?? "",
    Recommendation: item.recommendation ?? "",
    Action: item.action ?? "",
    Status: item.status,
    Outcome: item.outcome ?? "",
    Created: item.timestamp ?? item.created_at ?? "",
  })))

  if (loading) return <LoadingSpinner message="Loading interventions…" />

  return (
    <PageShell>
      <div className="flex flex-wrap items-end justify-between gap-3">
        <PageHeader title="Interventions" sub="Track, create, update and resolve student support actions. PROK recommends; staff decide." />
        <div className="mb-6 flex flex-wrap gap-2"><button onClick={exportItems} disabled={!filtered.length} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export CSV</button><button onClick={() => void load(true)} disabled={refreshing} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">{refreshing ? "Refreshing…" : "↻ Refresh"}</button><button onClick={beginCreate} className="rounded-xl bg-blue-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-800">＋ New intervention</button></div>
      </div>
      {notice && <div role="status" className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{notice}<button onClick={() => setNotice("")} aria-label="Dismiss message" className="float-right font-bold">×</button></div>}
      {error && <ErrorMessage message={error} onRetry={() => void load(true)} />}

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3"><StatCard label="Open" value={counts.OPEN} color="#DC2626" /><StatCard label="In Progress" value={counts.IN_PROGRESS} color="#D97706" /><StatCard label="Resolved" value={counts.RESOLVED} color="#059669" /></div>
      <div className="grid grid-cols-1 gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-[minmax(0,1fr)_240px]">
        <label className="text-xs font-bold uppercase tracking-wide text-slate-500">Search interventions<input type="search" value={search} onChange={e => setSearch(e.target.value)} placeholder="Student, issue, action or outcome…" className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm font-normal normal-case outline-none focus:border-blue-400" /></label>
        <label className="text-xs font-bold uppercase tracking-wide text-slate-500">Status<select value={filter} onChange={e => setFilter(e.target.value)} className="mt-1.5 w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm font-normal normal-case">{["ALL","OPEN","IN_PROGRESS","RESOLVED"].map(s => <option key={s} value={s}>{s === "ALL" ? "All statuses" : s.replace("_"," ")}</option>)}</select></label>
      </div>
      <div className="flex items-center justify-between text-sm text-slate-500"><span>Showing <strong className="text-slate-800">{filtered.length}</strong> of {items.length} interventions</span></div>

      {formOpen && <form onSubmit={submit} className="rounded-2xl border border-blue-100 bg-white p-5 shadow-sm"><div className="mb-4"><h3 className="text-lg font-bold text-slate-900">{editing ? "Edit intervention" : "Create intervention"}</h3><p className="mt-1 text-sm text-slate-500">{editing ? "Update the case notes or status." : "Enter the student's college ID and describe the issue and planned support action."}</p></div>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {!editing && <label className="text-sm font-medium text-slate-700">Student college ID<input required value={form.student_id} onChange={e => setForm({...form,student_id:e.target.value})} list="prok-student-ids" placeholder="e.g. STU001" className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /><datalist id="prok-student-ids">{students.map(s => <option key={s.college_id} value={s.college_id}>{s.full_name || s.name || s.email}</option>)}</datalist>{students.length > 0 && <span className="mt-1 block text-xs font-normal text-slate-400">Start typing to choose an existing student.</span>}</label>}
          <label className="text-sm font-medium text-slate-700 md:col-span-2">Issue<input required minLength={3} value={form.issue} onChange={e => setForm({...form,issue:e.target.value})} placeholder="Describe the support need" className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
          <label className="text-sm font-medium text-slate-700 md:col-span-2">Recommendation<textarea required minLength={3} rows={2} value={form.recommendation} onChange={e => setForm({...form,recommendation:e.target.value})} placeholder="What support should be offered?" className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
          <label className="text-sm font-medium text-slate-700 md:col-span-2">Planned action<textarea required minLength={3} rows={2} value={form.action} onChange={e => setForm({...form,action:e.target.value})} placeholder="Define the follow-up action" className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
          <label className="text-sm font-medium text-slate-700">Status<select value={form.status} onChange={e => setForm({...form,status:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 outline-none focus:border-blue-400">{["OPEN","IN_PROGRESS","RESOLVED"].map(s => <option key={s} value={s}>{s.replace("_"," ")}</option>)}</select></label>
          <label className="text-sm font-medium text-slate-700">Outcome / follow-up note<input value={form.outcome} onChange={e => setForm({...form,outcome:e.target.value})} placeholder="Optional" className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
        </div><div className="mt-5 flex justify-end gap-2"><button type="button" onClick={() => {setFormOpen(false);setEditing(null)}} className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50">Cancel</button><button disabled={saving} className="rounded-xl bg-blue-700 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-800 disabled:opacity-50">{saving ? "Saving…" : editing ? "Save changes" : "Create intervention"}</button></div>
      </form>}

      {filtered.length === 0 ? <EmptyState title="No interventions match this view" sub="Try a different search or create a new support intervention." /> : <div className="space-y-3">
        {filtered.map(item => {
          const id = item._id
          const studentId = item.student_id ?? ""
          const studentName = item.student_name || studentNames.get(studentId) || studentId || "Unknown student"
          return <article key={id} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md">
            <div className="flex flex-wrap items-start justify-between gap-3"><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><h3 className="font-bold text-slate-900">{studentName}</h3><Badge status={item.status} /></div><p className="mt-2 text-sm text-slate-700">{item.issue || item.reason || item.intervention_type || "Support need not specified"}</p><p className="mt-1 text-xs text-slate-400">Created {(item.timestamp ?? item.created_at ?? "").slice(0,10) || "date unavailable"}{studentId ? ` · ID: ${studentId}` : ""}</p></div><button onClick={() => beginEdit(item)} className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 hover:border-blue-200 hover:text-blue-700">Edit details</button></div>
            {(item.recommendation || item.action || item.outcome) && <div className="mt-4 grid grid-cols-1 gap-3 border-t border-slate-100 pt-4 md:grid-cols-3">{item.recommendation && <div><p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Recommendation</p><p className="mt-1 text-sm leading-5 text-slate-600">{item.recommendation}</p></div>}{item.action && <div><p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Planned action</p><p className="mt-1 text-sm leading-5 text-slate-600">{item.action}</p></div>}{item.outcome && <div><p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Outcome</p><p className="mt-1 text-sm leading-5 text-slate-600">{item.outcome}</p></div>}</div>}
            <div className="mt-4 flex flex-wrap gap-2 border-t border-slate-100 pt-4">{item.status === "OPEN" && <button onClick={() => void updateStatus(id,"IN_PROGRESS")} disabled={updating === id} className="rounded-lg bg-amber-50 px-3 py-2 text-xs font-bold text-amber-800 hover:bg-amber-100 disabled:opacity-50">{updating === id ? "Saving…" : "▶ Start"} </button>}{item.status !== "RESOLVED" && <button onClick={() => void updateStatus(id,"RESOLVED")} disabled={updating === id} className="rounded-lg bg-emerald-50 px-3 py-2 text-xs font-bold text-emerald-800 hover:bg-emerald-100 disabled:opacity-50">{updating === id ? "Saving…" : "✓ Mark resolved"}</button>}{item.status === "RESOLVED" && <button onClick={() => void updateStatus(id,"OPEN")} disabled={updating === id} className="rounded-lg bg-slate-100 px-3 py-2 text-xs font-bold text-slate-700 hover:bg-slate-200 disabled:opacity-50">Reopen case</button>}{studentId && <button onClick={() => navigate("/students")} className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-50">Open student directory →</button>}</div>
          </article>
        })}
      </div>}
    </PageShell>
  )
}
