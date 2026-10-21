import { useCallback, useEffect, useMemo, useState } from "react"
import { adminApi } from "../services/admin"
import { downloadCsv } from "../utils/exportCsv"

interface Doc {
  _id: string
  title: string
  doc_type: string
  status: string
  student_name?: string
  uploaded_at: string
  review_note?: string
}

const statusColor: Record<string, string> = {
  UNDER_REVIEW: "bg-amber-100 text-amber-800",
  VERIFIED: "bg-emerald-100 text-emerald-800",
  REJECTED: "bg-red-100 text-red-800",
}

export default function DocumentsPage() {
  const [docs, setDocs] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState("")
  const [notice, setNotice] = useState("")
  const [filter, setFilter] = useState("ALL")
  const [search, setSearch] = useState("")
  const [reviewNote, setReviewNote] = useState("")
  const [actionId, setActionId] = useState("")
  const [busyId, setBusyId] = useState("")

  const load = useCallback(async (quiet = false) => {
    if (quiet) setRefreshing(true)
    else setLoading(true)
    setError("")
    try {
      const data = await adminApi.getDocuments()
      setDocs(Array.isArray(data) ? data : data?.documents ?? [])
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load documents.")
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => { void load() }, [load])

  const counts = useMemo(() => ({
    ALL: docs.length,
    UNDER_REVIEW: docs.filter(d => d.status === "UNDER_REVIEW").length,
    VERIFIED: docs.filter(d => d.status === "VERIFIED").length,
    REJECTED: docs.filter(d => d.status === "REJECTED").length,
  }), [docs])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return docs.filter(d => (filter === "ALL" || d.status === filter) &&
      (!q || [d.title, d.doc_type, d.student_name ?? "", d.status, d.review_note ?? ""].some(v => v.toLowerCase().includes(q))))
  }, [docs, filter, search])

  const handleAction = async (id: string, action: "verify" | "reject") => {
    const doc = docs.find(d => d._id === id)
    if (action === "reject" && !reviewNote.trim() && !window.confirm("Reject this document without a review note?")) return
    setBusyId(id)
    setError("")
    setNotice("")
    try {
      if (action === "verify") await adminApi.verifyDocument(id, reviewNote.trim())
      else await adminApi.rejectDocument(id, reviewNote.trim())
      setReviewNote("")
      setActionId("")
      setNotice(`“${doc?.title || "Document"}” marked ${action === "verify" ? "verified" : "rejected"}.`)
      await load(true)
    } catch (e) {
      setError(e instanceof Error ? e.message : "Document review failed.")
    } finally {
      setBusyId("")
    }
  }

  const exportDocs = () => downloadCsv("prok-documents.csv", filtered.map(d => ({
    Title: d.title,
    Type: d.doc_type,
    Student: d.student_name ?? "",
    Status: d.status,
    "Uploaded At": d.uploaded_at ?? "",
    "Review Note": d.review_note ?? "",
  })))

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div><p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-600">Verification queue</p><h2 className="mt-1 text-3xl font-bold text-slate-900">Documents</h2><p className="mt-2 text-sm text-slate-500">Review document status and record a decision. Decisions are saved through the admin API.</p></div>
        <div className="mb-1 flex flex-wrap gap-2"><button onClick={exportDocs} disabled={!filtered.length} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export CSV</button><button onClick={() => void load(true)} disabled={refreshing} className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">{refreshing ? "Refreshing…" : "↻ Refresh"}</button></div>
      </div>
      {notice && <div role="status" className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">{notice}<button onClick={() => setNotice("")} className="float-right font-bold" aria-label="Dismiss message">×</button></div>}
      {error && <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"><span>{error}</span><button onClick={() => void load(true)} className="rounded-lg bg-red-700 px-3 py-1.5 font-semibold text-white hover:bg-red-800">Retry</button></div>}

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {(["ALL","UNDER_REVIEW","VERIFIED","REJECTED"] as const).map(f => <button key={f} onClick={() => setFilter(f)} aria-pressed={filter === f} className={"rounded-2xl border p-4 text-left transition " + (filter === f ? "border-blue-300 bg-blue-50 ring-2 ring-blue-100" : "border-slate-200 bg-white hover:border-slate-300")}>
          <span className="block text-xs font-bold uppercase tracking-wide text-slate-500">{f === "ALL" ? "All documents" : f.replace("_"," ")}</span><span className="mt-1 block text-2xl font-bold tabular-nums text-slate-900">{counts[f]}</span>
        </button>)}
      </div>

      <label className="block max-w-xl text-xs font-bold uppercase tracking-wide text-slate-500">Search documents<input type="search" value={search} onChange={e => setSearch(e.target.value)} placeholder="Search title, student, type, status or review note…" className="mt-1.5 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-normal normal-case outline-none focus:border-blue-400 focus:ring-4 focus:ring-blue-50" /></label>
      <div className="flex items-center justify-between text-sm text-slate-500"><span>Showing <strong className="text-slate-800">{filtered.length}</strong> of {docs.length} documents</span>{loading && <span>Loading…</span>}</div>

      {loading && docs.length === 0 ? <div className="flex h-44 items-center justify-center gap-3 text-sm text-slate-500"><span className="h-7 w-7 animate-spin rounded-full border-2 border-slate-200 border-t-blue-700" />Loading documents…</div>
      : filtered.length === 0 ? <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-16 text-center"><div className="text-4xl">📄</div><p className="mt-3 font-semibold text-slate-800">No matching documents</p><p className="mt-1 text-sm text-slate-500">Try another status or search query.</p><button onClick={() => {setFilter("ALL");setSearch("")}} className="mt-4 text-sm font-semibold text-blue-700">Clear filters</button></div>
      : <div className="space-y-3">{filtered.map(doc => <article key={doc._id} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md">
          <div className="flex flex-wrap items-start justify-between gap-3"><div className="min-w-0"><h3 className="break-words font-bold text-slate-900">{doc.title || "Untitled document"}</h3><p className="mt-1 text-sm text-slate-500">{doc.doc_type || "Document"} <span className="mx-1 text-slate-300">•</span>{doc.student_name || "Unknown student"}</p><p className="mt-1 text-xs text-slate-400">Uploaded {doc.uploaded_at?.slice(0,10) || "date unavailable"}</p></div><span className={"rounded-full px-3 py-1 text-xs font-bold " + (statusColor[doc.status] ?? "bg-slate-100 text-slate-600")}>{(doc.status || "UNKNOWN").replace("_"," ")}</span></div>
          {doc.review_note && <div className="mt-4 rounded-xl bg-slate-50 px-3 py-2.5 text-sm text-slate-600"><span className="font-semibold">Last review note:</span> {doc.review_note}</div>}
          {doc.status === "UNDER_REVIEW" && <div className="mt-4 border-t border-slate-100 pt-4">
            {actionId === doc._id ? <div className="space-y-3"><label className="block text-xs font-semibold uppercase tracking-wide text-slate-500">Review note <span className="font-normal normal-case">(optional for verification; recommended for rejection)</span><textarea rows={2} value={reviewNote} onChange={e => setReviewNote(e.target.value)} placeholder="Explain the decision for the audit trail…" className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm font-normal normal-case outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-50" /></label><div className="flex flex-wrap gap-2"><button onClick={() => void handleAction(doc._id,"verify")} disabled={busyId === doc._id} className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 disabled:opacity-50">{busyId === doc._id ? "Saving…" : "✓ Verify document"}</button><button onClick={() => void handleAction(doc._id,"reject")} disabled={busyId === doc._id} className="rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50">Reject document</button><button onClick={() => {setActionId("");setReviewNote("")}} disabled={busyId === doc._id} className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50">Cancel</button></div></div>
            : <button onClick={() => {setActionId(doc._id);setReviewNote("");setError("")}} className="rounded-lg bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700 hover:bg-blue-100">Review document →</button>}
          </div>}
        </article>)}</div>}
    </div>
  )
}
