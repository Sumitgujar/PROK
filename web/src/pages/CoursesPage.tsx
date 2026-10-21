import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react"
import { coursesApi, type CourseCreateInput } from "../services/courses"
import { downloadCsv } from "../utils/exportCsv"

interface Course {
  _id: string
  title: string
  course_code: string
  department: string
  credits: number
  description?: string
  teacher_name?: string
  enrolled_count?: number
  is_active: boolean
  tags?: string[]
}

const blankCourse = { title: "", course_code: "", department: "Computer Science", credits: "3", description: "", tags: "" }

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState("")
  const [notice, setNotice] = useState("")
  const [search, setSearch] = useState("")
  const [deptFilter, setDeptFilter] = useState("ALL")
  const [showCreate, setShowCreate] = useState(false)
  const [form, setForm] = useState(blankCourse)
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState<string | null>(null)
  const [selected, setSelected] = useState<Course | null>(null)

  const load = useCallback(async (quiet = false) => {
    if (quiet) setRefreshing(true)
    else setLoading(true)
    setError("")
    try {
      const data = await coursesApi.getCourses()
      setCourses(Array.isArray(data) ? data : data?.courses ?? [])
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load courses.")
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => { void load() }, [load])

  const depts = useMemo(() => ["ALL", ...Array.from(new Set(courses.map(c => c.department).filter(Boolean))).sort()], [courses])
  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return courses.filter(c => {
      const matchesText = !q || [c.title, c.course_code, c.department, c.teacher_name ?? "", c.description ?? "", ...(c.tags ?? [])].some(v => String(v).toLowerCase().includes(q))
      return matchesText && (deptFilter === "ALL" || c.department === deptFilter)
    }).sort((a,b) => a.title.localeCompare(b.title))
  }, [courses, search, deptFilter])

  const createCourse = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaving(true); setError(""); setNotice("")
    const data: CourseCreateInput = {
      title: form.title.trim(),
      course_code: form.course_code.trim().toUpperCase(),
      department: form.department.trim(),
      credits: Number(form.credits),
      description: form.description.trim(),
      tags: form.tags.split(",").map(tag => tag.trim()).filter(Boolean),
    }
    try {
      await coursesApi.createCourse(data)
      setForm(blankCourse); setShowCreate(false)
      setNotice(`Course ${data.course_code} created successfully.`)
      await load(true)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Course could not be created.")
    } finally { setSaving(false) }
  }

  const removeCourse = async (course: Course) => {
    if (!window.confirm(`Delete course ${course.course_code} — ${course.title}? The course record will be removed from the catalogue.`)) return
    setDeleting(course._id); setError(""); setNotice("")
    try {
      await coursesApi.deleteCourse(course._id)
      setCourses(items => items.filter(item => item._id !== course._id))
      setSelected(null)
      setNotice(`Course ${course.course_code} deleted.`)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Course could not be deleted.")
    } finally { setDeleting(null) }
  }

  const exportCourses = () => downloadCsv("prok-courses.csv", filtered.map(c => ({
    Title: c.title, "Course Code": c.course_code, Department: c.department, Credits: c.credits,
    Teacher: c.teacher_name ?? "", "Enrolled Students": c.enrolled_count ?? 0, Status: c.is_active ? "Active" : "Inactive",
    Tags: (c.tags ?? []).join("; "), Description: c.description ?? "",
  })))

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3"><div><p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-600">Academic catalogue</p><h2 className="mt-1 text-3xl font-bold text-slate-900">Courses</h2><p className="mt-2 text-sm text-slate-500">Search the course catalogue, view course details, and create records in MongoDB.</p></div><div className="mb-1 flex flex-wrap gap-2"><button onClick={exportCourses} disabled={!filtered.length} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export CSV</button><button onClick={() => void load(true)} disabled={refreshing} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">{refreshing ? "Refreshing…" : "↻ Refresh"}</button><button onClick={() => {setShowCreate(v => !v);setNotice("");setError("")}} className="rounded-xl bg-blue-700 px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-800">{showCreate ? "Cancel" : "＋ Add course"}</button></div></div>
      {notice && <div role="status" className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{notice}<button onClick={() => setNotice("")} aria-label="Dismiss message" className="float-right font-bold">×</button></div>}
      {error && <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"><span>{error}</span><button onClick={() => void load(true)} className="rounded-lg bg-red-700 px-3 py-1.5 font-semibold text-white hover:bg-red-800">Retry</button></div>}

      {showCreate && <form onSubmit={createCourse} className="rounded-2xl border border-blue-100 bg-white p-5 shadow-sm"><h3 className="text-lg font-bold text-slate-900">Create course</h3><p className="mb-4 mt-1 text-sm text-slate-500">The existing FastAPI admin endpoint will persist this course.</p>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
          <label className="text-sm font-medium text-slate-700">Course title<input required minLength={2} value={form.title} onChange={e => setForm({...form,title:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
          <label className="text-sm font-medium text-slate-700">Course code<input required value={form.course_code} onChange={e => setForm({...form,course_code:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 uppercase outline-none focus:border-blue-400" /></label>
          <label className="text-sm font-medium text-slate-700">Department<input required value={form.department} onChange={e => setForm({...form,department:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
          <label className="text-sm font-medium text-slate-700">Credits<input required type="number" min="1" max="12" value={form.credits} onChange={e => setForm({...form,credits:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
          <label className="text-sm font-medium text-slate-700 sm:col-span-2">Tags <span className="font-normal text-slate-400">(comma separated)</span><input value={form.tags} onChange={e => setForm({...form,tags:e.target.value})} placeholder="Python, Data Science, AI" className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
          <label className="text-sm font-medium text-slate-700 sm:col-span-2 xl:col-span-3">Description<textarea rows={2} value={form.description} onChange={e => setForm({...form,description:e.target.value})} className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 outline-none focus:border-blue-400" /></label>
        </div><div className="mt-5 flex justify-end gap-2"><button type="button" onClick={() => {setShowCreate(false);setForm(blankCourse)}} className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50">Cancel</button><button disabled={saving} className="rounded-xl bg-blue-700 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-800 disabled:opacity-50">{saving ? "Creating…" : "Create course"}</button></div>
      </form>}

      <div className="grid grid-cols-1 gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-[minmax(0,1fr)_260px]"><label className="text-xs font-bold uppercase tracking-wide text-slate-500">Search catalogue<input type="search" value={search} onChange={e => setSearch(e.target.value)} placeholder="Title, code, teacher, tag…" className="mt-1.5 w-full rounded-lg border border-slate-200 px-3 py-2.5 text-sm font-normal normal-case outline-none focus:border-blue-400" /></label><label className="text-xs font-bold uppercase tracking-wide text-slate-500">Department<select value={deptFilter} onChange={e => setDeptFilter(e.target.value)} className="mt-1.5 w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm font-normal normal-case"><option value="ALL">All departments</option>{depts.filter(d => d !== "ALL").map(d => <option key={d} value={d}>{d}</option>)}</select></label></div>
      <div className="flex items-center justify-between text-sm text-slate-500"><span>Showing <strong className="text-slate-800">{filtered.length}</strong> of {courses.length} courses</span></div>

      {loading && courses.length === 0 ? <div className="flex h-44 items-center justify-center gap-3 text-sm text-slate-500"><span className="h-7 w-7 animate-spin rounded-full border-2 border-slate-200 border-t-blue-700" />Loading courses…</div>
      : filtered.length === 0 ? <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-16 text-center"><div className="text-4xl">📚</div><p className="mt-3 font-semibold text-slate-800">No matching courses</p><p className="mt-1 text-sm text-slate-500">Try a different search or department.</p><button onClick={() => {setSearch("");setDeptFilter("ALL")}} className="mt-4 text-sm font-semibold text-blue-700">Clear filters</button></div>
      : <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">{filtered.map(c => <article key={c._id} className="flex flex-col rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
        <div className="flex items-start justify-between gap-2"><span className="rounded-lg bg-blue-50 px-2.5 py-1 text-xs font-bold text-blue-700">{c.course_code}</span><span className={"rounded-full px-2.5 py-1 text-xs font-semibold " + (c.is_active ? "bg-emerald-50 text-emerald-700" : "bg-slate-100 text-slate-500")}>{c.is_active ? "Active" : "Inactive"}</span></div>
        <h3 className="mt-4 text-lg font-bold text-slate-900">{c.title}</h3><p className="mt-1 text-sm text-slate-500">{c.department || "Department not specified"}</p><p className="mt-2 text-xs text-slate-400">Instructor: {c.teacher_name || "TBA"}</p>
        <div className="mt-4 flex flex-wrap gap-3 text-xs text-slate-500"><span>📊 {c.credits} credits</span>{c.enrolled_count != null && <span>👥 {c.enrolled_count} enrolled</span>}</div>
        {c.tags?.length ? <div className="mt-4 flex flex-wrap gap-1.5">{c.tags.slice(0,4).map(t => <span key={t} className="rounded-full bg-slate-100 px-2.5 py-1 text-xs text-slate-600">{t}</span>)}</div> : null}
        <div className="mt-auto flex gap-2 border-t border-slate-100 pt-4 mt-5"><button onClick={() => setSelected(c)} className="flex-1 rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-700 hover:border-blue-200 hover:text-blue-700">Details</button><button onClick={() => void removeCourse(c)} disabled={deleting === c._id} className="rounded-lg px-3 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50">{deleting === c._id ? "Deleting…" : "Delete"}</button></div>
      </article>)}</div>}

      {selected && <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 p-4" onMouseDown={e => {if(e.target === e.currentTarget) setSelected(null)}}><section role="dialog" aria-modal="true" aria-labelledby="course-dialog-title" className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl"><div className="flex items-start justify-between"><div><p className="text-xs font-bold uppercase tracking-[0.18em] text-blue-600">Course details</p><h3 id="course-dialog-title" className="mt-1 text-xl font-bold text-slate-900">{selected.title}</h3><p className="mt-1 text-sm text-slate-500">{selected.course_code}</p></div><button onClick={() => setSelected(null)} aria-label="Close details" className="rounded-lg px-2 py-1 text-xl text-slate-400 hover:bg-slate-100">×</button></div><div className="mt-5 grid grid-cols-2 gap-3">{[["Department",selected.department],["Credits",selected.credits],["Instructor",selected.teacher_name || "TBA"],["Enrolled",selected.enrolled_count ?? 0],["Status",selected.is_active ? "Active" : "Inactive"],["Tags",selected.tags?.join(", ") || "None"]].map(([label,value]) => <div key={label} className="rounded-xl bg-slate-50 p-3"><p className="text-xs text-slate-500">{label}</p><p className="mt-1 break-words text-sm font-semibold text-slate-800">{value ?? "—"}</p></div>)}</div>{selected.description && <p className="mt-4 rounded-xl bg-slate-50 p-3 text-sm leading-6 text-slate-600">{selected.description}</p>}<div className="mt-6 flex justify-end"><button onClick={() => setSelected(null)} className="rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-slate-800">Close</button></div></section></div>}
    </div>
  )
}
