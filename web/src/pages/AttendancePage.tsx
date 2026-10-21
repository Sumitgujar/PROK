import { useCallback, useEffect, useMemo, useState } from "react"
import { attendanceApi } from "../services/attendance"
import { downloadCsv } from "../utils/exportCsv"

interface Session {
  _id: string
  course_title: string
  course_code: string
  date: string
  present: number
  absent: number
  total: number
  notes?: string
}
interface AttendanceRecord {
  _id?: string
  student_name?: string
  student_id: string
  status: string
  marked_at?: string
}

export default function AttendancePage() {
  const [sessions, setSessions] = useState<Session[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState("")
  const [search, setSearch] = useState("")
  const [expanded, setExpanded] = useState<string | null>(null)
  const [recordsBySession, setRecordsBySession] = useState<Record<string, AttendanceRecord[]>>({})
  const [recordErrors, setRecordErrors] = useState<Record<string, string>>({})
  const [loadingSession, setLoadingSession] = useState<string | null>(null)

  const load = useCallback(async (quiet = false) => {
    if (quiet) setRefreshing(true)
    else setLoading(true)
    setError("")
    try {
      const data = await attendanceApi.getTodaySessions()
      const items = Array.isArray(data) ? data : data?.sessions ?? []
      setSessions(items)
      setRecordsBySession({})
      setRecordErrors({})
    } catch (e) {
      setError(e instanceof Error ? e.message : "Unable to load today's attendance sessions.")
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => { void load() }, [load])

  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase()
    return sessions.filter(s => !query || [s.course_title, s.course_code, s.date, s.notes ?? ""].some(v => String(v).toLowerCase().includes(query)))
      .sort((a,b) => (b.date || "").localeCompare(a.date || "") || (a.course_code || "").localeCompare(b.course_code || ""))
  }, [sessions, search])

  const totals = useMemo(() => sessions.reduce((result, s) => ({
    present: result.present + Number(s.present || 0),
    absent: result.absent + Number(s.absent || 0),
    total: result.total + Number(s.total || 0),
  }), { present: 0, absent: 0, total: 0 }), [sessions])

  const toggleSession = async (session: Session) => {
    if (expanded === session._id) { setExpanded(null); return }
    setExpanded(session._id)
    if (recordsBySession[session._id]) return
    setLoadingSession(session._id)
    setRecordErrors(prev => ({ ...prev, [session._id]: "" }))
    try {
      const data = await attendanceApi.getSessionRecords(session._id)
      setRecordsBySession(prev => ({ ...prev, [session._id]: Array.isArray(data) ? data : data?.records ?? [] }))
    } catch (e) {
      setRecordErrors(prev => ({ ...prev, [session._id]: e instanceof Error ? e.message : "Could not load student records." }))
    } finally { setLoadingSession(null) }
  }

  const exportSessions = () => downloadCsv("prok-todays-attendance-sessions.csv", filtered.map(s => ({
    Course: s.course_title ?? "",
    "Course Code": s.course_code ?? "",
    Date: s.date ?? "",
    Present: s.present ?? 0,
    Absent: s.absent ?? 0,
    Total: s.total ?? 0,
    "Attendance Rate (%)": s.total > 0 ? Math.round(s.present / s.total * 100) : 0,
    Notes: s.notes ?? "",
  })))

  const exportRecords = (session: Session) => {
    const records = recordsBySession[session._id] ?? []
    downloadCsv(`attendance-${session.course_code || "session"}-${session.date || "records"}.csv`, records.map(r => ({
      Course: session.course_title,
      Date: session.date,
      Student: r.student_name || r.student_id,
      "Student ID": r.student_id,
      Status: r.status,
      "Marked At": r.marked_at ?? "",
    })))
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3"><div><p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-600">Class records</p><h2 className="mt-1 text-3xl font-bold text-slate-900">Attendance</h2><p className="mt-2 text-sm text-slate-500">Today's attendance sessions. Expand a session to inspect students and export records.</p></div><div className="mb-1 flex gap-2"><button onClick={exportSessions} disabled={!filtered.length} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export CSV</button><button onClick={() => void load(true)} disabled={refreshing} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">{refreshing ? "Refreshing…" : "↻ Refresh"}</button></div></div>
      {error && <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"><span>{error}</span><button onClick={() => void load(true)} className="rounded-lg bg-red-700 px-3 py-1.5 font-semibold text-white hover:bg-red-800">Retry</button></div>}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        {[["Sessions",sessions.length,"bg-blue-50 text-blue-700"],["Present",totals.present,"bg-emerald-50 text-emerald-700"],["Absent",totals.absent,"bg-red-50 text-red-700"]].map(([label,value,tone]) => <div key={String(label)} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"><p className="text-xs font-bold uppercase tracking-wide text-slate-500">{label}</p><div className="mt-2 flex items-center justify-between"><span className="text-2xl font-bold tabular-nums text-slate-900">{Number(value).toLocaleString()}</span><span className={`rounded-xl px-3 py-1.5 text-xs font-bold ${tone}`}>{label === "Sessions" ? "Today" : label === "Present" ? "Recorded" : "Flagged"}</span></div></div>)}
      </div>
      <label className="block max-w-xl text-xs font-bold uppercase tracking-wide text-slate-500">Search sessions<input type="search" value={search} onChange={e => setSearch(e.target.value)} placeholder="Search course title, code or date…" className="mt-1.5 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-normal normal-case outline-none focus:border-blue-400 focus:ring-4 focus:ring-blue-50" /></label>
      {loading && sessions.length === 0 ? <div className="flex h-44 items-center justify-center gap-3 text-sm text-slate-500"><span className="h-7 w-7 animate-spin rounded-full border-2 border-slate-200 border-t-blue-700" />Loading today's sessions…</div>
      : filtered.length === 0 ? <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-16 text-center"><div className="text-4xl">📋</div><p className="mt-3 font-semibold text-slate-800">{sessions.length ? "No sessions match your search" : "No attendance sessions found for today"}</p><p className="mt-1 text-sm text-slate-500">{sessions.length ? "Try a different course or date." : "Sessions will appear when attendance has been recorded for today."}</p>{search && <button onClick={() => setSearch("")} className="mt-4 text-sm font-semibold text-blue-700">Clear search</button>}</div>
      : <div className="space-y-3">{filtered.map(s => {
        const rate = s.total > 0 ? Math.round(s.present / s.total * 100) : 0
        const isExpanded = expanded === s._id
        const records = recordsBySession[s._id] ?? []
        return <article key={s._id} className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <button type="button" aria-expanded={isExpanded} onClick={() => void toggleSession(s)} className="flex w-full flex-wrap items-center justify-between gap-4 p-5 text-left transition hover:bg-slate-50 focus:outline-none focus:ring-4 focus:ring-inset focus:ring-blue-50">
            <div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><h3 className="font-bold text-slate-900">{s.course_title || "Untitled course"}</h3><span className="rounded-md bg-slate-100 px-2 py-0.5 text-xs font-bold text-slate-600">{s.course_code || "—"}</span></div><p className="mt-1 text-sm text-slate-500">{s.date?.slice(0,10) || "Date unavailable"}</p><div className="mt-3 h-1.5 max-w-sm overflow-hidden rounded-full bg-slate-100"><div className={`h-full rounded-full ${rate >= 75 ? "bg-emerald-500" : rate >= 50 ? "bg-amber-500" : "bg-red-500"}`} style={{width:`${rate}%`}} /></div></div>
            <div className="flex items-center gap-4 sm:gap-6"><div className="text-center"><div className="font-bold text-emerald-700">{s.present ?? 0}</div><div className="text-xs text-slate-400">Present</div></div><div className="text-center"><div className="font-bold text-red-600">{s.absent ?? 0}</div><div className="text-xs text-slate-400">Absent</div></div><div className="text-center"><div className="font-bold text-blue-700">{rate}%</div><div className="text-xs text-slate-400">Rate</div></div><span className={`text-slate-400 transition-transform ${isExpanded ? "rotate-180" : ""}`}>⌄</span></div>
          </button>
          {isExpanded && <div className="border-t border-slate-100 bg-slate-50/60 p-4 sm:p-5">
            <div className="mb-3 flex flex-wrap items-center justify-between gap-2"><div><h4 className="font-bold text-slate-800">Student records</h4><p className="mt-1 text-xs text-slate-500">Records read from the database for this session.</p></div><button onClick={() => exportRecords(s)} disabled={!records.length} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export records</button></div>
            {loadingSession === s._id ? <div className="py-8 text-center text-sm text-slate-500">Loading records…</div>
            : recordErrors[s._id] ? <div role="alert" className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800">{recordErrors[s._id]} <button onClick={() => {setRecordsBySession(prev => {const next={...prev};delete next[s._id];return next});void toggleSession(s)}} className="ml-2 font-bold underline">Retry</button></div>
            : records.length === 0 ? <div className="rounded-xl border border-dashed border-slate-200 bg-white py-8 text-center text-sm text-slate-500">No student attendance records found.</div>
            : <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white"><table className="w-full min-w-[480px] text-sm"><thead className="bg-slate-50 text-[11px] uppercase tracking-wide text-slate-500"><tr><th className="px-4 py-3 text-left">Student</th><th className="px-4 py-3 text-left">Status</th><th className="px-4 py-3 text-left">Marked at</th></tr></thead><tbody className="divide-y divide-slate-100">{records.map((record,i) => <tr key={record._id ?? record.student_id ?? i}><td className="px-4 py-3"><p className="font-semibold text-slate-800">{record.student_name || record.student_id || "Unknown student"}</p>{record.student_name && <p className="mt-0.5 text-xs text-slate-400">{record.student_id}</p>}</td><td className="px-4 py-3"><span className={`rounded-full px-2.5 py-1 text-xs font-bold ${record.status === "present" ? "bg-emerald-100 text-emerald-800" : record.status === "late" ? "bg-amber-100 text-amber-800" : "bg-red-100 text-red-800"}`}>{record.status || "unknown"}</span></td><td className="px-4 py-3 text-slate-500">{record.marked_at ? new Date(record.marked_at).toLocaleString() : "—"}</td></tr>)}</tbody></table></div>}
          </div>}
        </article>
      })}</div>}
      <p className="text-xs text-slate-400">This page shows today's sessions only because the current admin endpoint is scoped to today's date. Historical reporting is available through the course-history endpoint where authorized.</p>
    </div>
  )
}
