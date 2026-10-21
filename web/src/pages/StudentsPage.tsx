import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react"
import { adminApi } from "../services/admin"
import { downloadCsv } from "../utils/exportCsv"

interface Student {
  _id: string
  full_name?: string
  name?: string
  email: string
  college_id: string
  department?: string
  semester?: number
  cgpa?: number
  is_active?: boolean
  created_at?: string
}

const emptyForm = { full_name: "", email: "", college_id: "", password: "student123", department: "Computer Science", semester: "1", year: "1", cgpa: "0" }

export default function StudentsPage() {
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")
  const [notice, setNotice] = useState("")
  const [search, setSearch] = useState("")
  const [deptFilter, setDeptFilter] = useState("ALL")
  const [sortBy, setSortBy] = useState<"name" | "cgpa" | "semester">("name")
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc")
  const [showCreate, setShowCreate] = useState(false)
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState<string | null>(null)
  const [selected, setSelected] = useState<Student | null>(null)
  const [form, setForm] = useState(emptyForm)

  const load = useCallback(async (quiet = false) => {
    if (!quiet) setLoading(true)
    setError("")
    try {
      const data = await adminApi.getStudents()
      setStudents(Array.isArray(data) ? data : data?.students ?? [])
    } catch (e) {
      setError(e instanceof Error ? e.message : "Unable to load students.")
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { void load() }, [load])

  const departments = useMemo(() => ["ALL", ...Array.from(new Set(students.map(s => s.department).filter((d): d is string => Boolean(d)))).sort()], [students])
  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase()
    return students.filter(s => {
      const name = s.full_name || s.name || ""
      const matchesQuery = !query || [name, s.email, s.college_id, s.department || ""].some(v => v.toLowerCase().includes(query))
      return matchesQuery && (deptFilter === "ALL" || s.department === deptFilter)
    }).sort((a,b) => {
      let comparison = 0
      if (sortBy === "cgpa") comparison = (a.cgpa ?? -1) - (b.cgpa ?? -1)
      else if (sortBy === "semester") comparison = (a.semester ?? 0) - (b.semester ?? 0)
      else comparison = (a.full_name || a.name || "").localeCompare(b.full_name || b.name || "")
      return sortDirection === "asc" ? comparison : -comparison
    })
  }, [students, search, deptFilter, sortBy, sortDirection])

  const submitCreate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaving(true)
    setError("")
    setNotice("")
    try {
      await adminApi.createStudent({
        full_name: form.full_name.trim(),
        email: form.email.trim(),
        college_id: form.college_id.trim(),
        password: form.password || "student123",
        department: form.department.trim(),
        semester: Number(form.semester),
        year: Number(form.year),
        cgpa: Number(form.cgpa),
      })
      setForm(emptyForm)
      setShowCreate(false)
      setNotice("Student account created successfully.")
      await load(true)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Student could not be created.")
    } finally {
      setSaving(false)
    }
  }

  const removeStudent = async (student: Student) => {
    const name = student.full_name || student.name || student.email
    if (!window.confirm(`Delete the student account for ${name}? This also removes the student's profile and course enrollments. This action cannot be undone.`)) return
    setDeleting(student._id)
    setError("")
    setNotice("")
    try {
      await adminApi.deleteStudent(student._id)
      setStudents(items => items.filter(item => item._id !== student._id))
      setSelected(null)
      setNotice(`Deleted student account for ${name}.`)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Student could not be deleted.")
    } finally {
      setDeleting(null)
    }
  }

  const exportStudents = () => downloadCsv("prok-students.csv", filtered.map(s => ({
    Name: s.full_name || s.name || "",
    Email: s.email,
    "College ID": s.college_id,
    Department: s.department || "",
    Semester: s.semester ?? "",
    CGPA: s.cgpa ?? "",
    Status: s.is_active === false ? "Inactive" : "Active",
  })))

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-600">Directory</p>
          <h2 className="mt-1 text-3xl font-bold text-slate-900">Students</h2>
          <p className="mt-2 text-sm text-slate-500">Search, inspect and manage student records connected to the database.</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button onClick={exportStudents} disabled={!filtered.length} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export CSV</button>
          <button onClick={() => { setShowCreate(v => !v); setNotice(""); setError("") }} className="rounded-xl bg-blue-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-800">{showCreate ? "Cancel" : "＋ Add student"}</button>
        </div>
      </div>

      {notice && <div role="status" className="flex items-center justify-between rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800"><span>{notice}</span><button onClick={() => setNotice("")} aria-label="Dismiss notification" className="ml-3 font-bold">×</button></div>}
      {error && <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"><span>{error}</span><button onClick={() => void load(true)} className="rounded-lg bg-red-700 px-3 py-1.5 font-semibold text-white hover:bg-red-800">Retry</button></div>}

      {showCreate && (
        <form onSubmit={submitCreate} className="rounded-2xl border border-blue-100 bg-white p-5 shadow-sm">
          <div className="mb-4"><h3 className="text-lg font-bold text-slate-900">Create student account</h3><p className="mt-1 text-sm text-slate-500">This saves the student through the existing admin API. Use a unique email and college ID.</p></div>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
            <label className="text-sm font-medium text-slate-700">Full name<input required minLength={2} value={form.full_name} onChange={e => setForm({...form, full_name:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label>
            <label className="text-sm font-medium text-slate-700">Email<input required type="email" value={form.email} onChange={e => setForm({...form, email:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label>
            <label className="text-sm font-medium text-slate-700">College ID<input required value={form.college_id} onChange={e => setForm({...form, college_id:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label>
            <label className="text-sm font-medium text-slate-700">Temporary password<input minLength={8} value={form.password} onChange={e => setForm({...form, password:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /><span className="mt-1 block text-xs font-normal text-slate-400">Change the demo default before real use.</span></label>
            <label className="text-sm font-medium text-slate-700">Department<input required value={form.department} onChange={e => setForm({...form, department:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label>
            <label className="text-sm font-medium text-slate-700">Semester<input required type="number" min="1" max="12" value={form.semester} onChange={e => setForm({...form, semester:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label>
            <label className="text-sm font-medium text-slate-700">Year<input required type="number" min="1" max="6" value={form.year} onChange={e => setForm({...form, year:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label>
            <label className="text-sm font-medium text-slate-700">CGPA<input required type="number" min="0" max="10" step="0.01" value={form.cgpa} onChange={e => setForm({...form, cgpa:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label>
          </div>
          <div className="mt-5 flex flex-wrap justify-end gap-2"><button type="button" onClick={() => { setShowCreate(false); setForm(emptyForm) }} className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50">Cancel</button><button disabled={saving} className="rounded-xl bg-blue-700 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-800 disabled:opacity-60">{saving ? "Creating…" : "Create student"}</button></div>
        </form>
      )}

      <div className="grid grid-cols-1 gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-[minmax(0,1fr)_220px_190px_auto]">
        <label className="text-xs font-semibold uppercase tracking-wide text-slate-500">Search students<input type="search" placeholder="Name, email, ID or department" value={search} onChange={e => setSearch(e.target.value)} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm font-normal normal-case outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label>
        <label className="text-xs font-semibold uppercase tracking-wide text-slate-500">Department<select value={deptFilter} onChange={e => setDeptFilter(e.target.value)} className="mt-1.5 w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm font-normal normal-case"><option value="ALL">All departments</option>{departments.filter(d => d !== "ALL").map(d => <option key={d} value={d}>{d}</option>)}</select></label>
        <label className="text-xs font-semibold uppercase tracking-wide text-slate-500">Sort by<select value={sortBy} onChange={e => setSortBy(e.target.value as typeof sortBy)} className="mt-1.5 w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm font-normal normal-case"><option value="name">Name</option><option value="cgpa">CGPA</option><option value="semester">Semester</option></select></label>
        <button onClick={() => setSortDirection(v => v === "asc" ? "desc" : "asc")} className="self-end rounded-lg border border-slate-200 px-3 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50" title="Reverse sort order">{sortDirection === "asc" ? "↑ Ascending" : "↓ Descending"}</button>
      </div>

      <div className="flex items-center justify-between gap-3 text-sm text-slate-500"><span>Showing <strong className="text-slate-800">{filtered.length}</strong> of <strong className="text-slate-800">{students.length}</strong> students</span><button onClick={() => void load(true)} disabled={loading} className="font-semibold text-blue-700 hover:text-blue-900 disabled:opacity-50">↻ Reload records</button></div>

      {loading ? <div className="flex h-48 items-center justify-center gap-3 text-sm text-slate-500"><span className="h-7 w-7 animate-spin rounded-full border-2 border-slate-200 border-t-blue-700" />Loading students…</div>
       : filtered.length === 0 ? <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-16 text-center"><div className="text-4xl">🎓</div><p className="mt-3 font-semibold text-slate-800">{students.length ? "No students match these filters" : "No student records yet"}</p><p className="mt-1 text-sm text-slate-500">Try a different search or add a student account.</p>{(search || deptFilter !== "ALL") && <button onClick={() => {setSearch("");setDeptFilter("ALL")}} className="mt-4 text-sm font-semibold text-blue-700">Clear filters</button>}</div>
       : <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"><div className="overflow-x-auto"><table className="w-full min-w-[720px] text-sm">
          <thead className="bg-slate-50 text-[11px] uppercase tracking-wider text-slate-500"><tr><th className="px-5 py-3 text-left">Student</th><th className="px-5 py-3 text-left">College ID</th><th className="px-5 py-3 text-left">Department</th><th className="px-5 py-3 text-left">Semester</th><th className="px-5 py-3 text-left">CGPA</th><th className="px-5 py-3 text-right">Actions</th></tr></thead>
          <tbody className="divide-y divide-slate-100">{filtered.map(s => <tr key={s._id} className="transition hover:bg-blue-50/40">
            <td className="px-5 py-4"><button onClick={() => setSelected(s)} className="text-left font-semibold text-slate-800 hover:text-blue-700 hover:underline">{s.full_name || s.name || "Unnamed student"}</button><div className="mt-1 text-xs text-slate-400">{s.email}</div></td>
            <td className="px-5 py-4 font-mono text-xs text-slate-600">{s.college_id || "—"}</td><td className="px-5 py-4 text-slate-600">{s.department || "—"}</td><td className="px-5 py-4 text-slate-600">{s.semester ?? "—"}</td><td className="px-5 py-4">{s.cgpa != null ? <span className="rounded-lg bg-slate-100 px-2 py-1 font-semibold text-slate-700">{Number(s.cgpa).toFixed(2)}</span> : "—"}</td>
            <td className="px-5 py-4 text-right"><button onClick={() => setSelected(s)} className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-600 hover:border-blue-200 hover:text-blue-700">Details</button><button onClick={() => void removeStudent(s)} disabled={deleting === s._id} className="ml-2 rounded-lg px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50">{deleting === s._id ? "Deleting…" : "Delete"}</button></td>
          </tr>)}</tbody></table></div></div>}

      {selected && <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 p-4" role="presentation" onMouseDown={event => { if (event.target === event.currentTarget) setSelected(null) }}><section role="dialog" aria-modal="true" aria-labelledby="student-detail-title" className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl">
        <div className="flex items-start justify-between"><div><p className="text-xs font-bold uppercase tracking-[0.18em] text-blue-600">Student profile</p><h3 id="student-detail-title" className="mt-1 text-xl font-bold text-slate-900">{selected.full_name || selected.name || "Unnamed student"}</h3><p className="mt-1 text-sm text-slate-500">{selected.email}</p></div><button onClick={() => setSelected(null)} aria-label="Close student details" className="rounded-lg px-2 py-1 text-xl text-slate-400 hover:bg-slate-100">×</button></div>
        <div className="mt-5 grid grid-cols-2 gap-3">{[["College ID",selected.college_id],["Department",selected.department],["Semester",selected.semester],["CGPA",selected.cgpa == null ? "—" : Number(selected.cgpa).toFixed(2)],["Account status",selected.is_active === false ? "Inactive" : "Active"],["Created",selected.created_at?.slice(0,10) || "—"]].map(([label,value]) => <div key={label} className="rounded-xl bg-slate-50 p-3"><p className="text-xs font-medium text-slate-500">{label}</p><p className="mt-1 break-words text-sm font-semibold text-slate-800">{value ?? "—"}</p></div>)}</div>
        <div className="mt-6 flex justify-end"><button onClick={() => setSelected(null)} className="rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-slate-800">Close</button></div>
      </section></div>}
    </div>
  )
}
