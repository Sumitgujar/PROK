import { useEffect, useState } from 'react'
import { adminApi } from '../services/admin'

interface Doc { _id: string; title: string; doc_type: string; status: string; student_name?: string; uploaded_at: string; review_note?: string; }

const statusColor: Record<string, string> = {
  UNDER_REVIEW: 'bg-yellow-100 text-yellow-700',
  VERIFIED: 'bg-green-100 text-green-700',
  REJECTED: 'bg-red-100 text-red-700',
}

export default function DocumentsPage() {
  const [docs, setDocs] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [filter, setFilter] = useState('ALL')
  const [reviewNote, setReviewNote] = useState('')
  const [actionId, setActionId] = useState('')

  const load = () => {
    setLoading(true)
    adminApi.getDocuments()
      .then(data => setDocs(Array.isArray(data) ? data : data.documents ?? []))
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  const handleAction = async (id: string, action: 'verify' | 'reject') => {
    try {
      if (action === 'verify') await adminApi.verifyDocument(id, reviewNote)
      else await adminApi.rejectDocument(id, reviewNote)
      setReviewNote('')
      setActionId('')
      load()
    } catch (e: any) { alert(e.message) }
  }

  const filtered = filter === 'ALL' ? docs : docs.filter(d => d.status === filter)

  if (loading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-900" /></div>
  if (error) return <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-lg">Error: {error}</div>

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Documents</h1>
      <div className="flex gap-2 mb-4">
        {['ALL','UNDER_REVIEW','VERIFIED','REJECTED'].map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition ${
              filter === f ? 'bg-blue-900 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {f === 'ALL' ? 'All' : f.replace('_', ' ')}
          </button>
        ))}
      </div>
      {filtered.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <div className="text-5xl mb-3">📄</div>
          <p className="text-lg font-medium">No documents found</p>
        </div>
      ) : (
        <div className="space-y-4">
          {filtered.map(doc => (
            <div key={doc._id} className="bg-white rounded-xl shadow p-5">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-semibold text-gray-800">{doc.title}</h3>
                  <p className="text-sm text-gray-500">{doc.doc_type} • {doc.student_name || 'Unknown student'}</p>
                  <p className="text-xs text-gray-400 mt-1">{doc.uploaded_at?.slice(0,10)}</p>
                  {doc.review_note && <p className="text-xs text-gray-500 mt-1">Note: {doc.review_note}</p>}
                </div>
                <span className={`text-xs font-semibold px-3 py-1 rounded-full ${statusColor[doc.status] ?? 'bg-gray-100 text-gray-600'}`}>
                  {doc.status.replace('_',' ')}
                </span>
              </div>
              {doc.status === 'UNDER_REVIEW' && (
                <div className="mt-4 border-t pt-4">
                  {actionId === doc._id ? (
                    <div className="flex gap-2">
                      <input value={reviewNote} onChange={e => setReviewNote(e.target.value)}
                        className="flex-1 border rounded-lg px-3 py-2 text-sm" placeholder="Review note (optional)" />
                      <button onClick={() => handleAction(doc._id, 'verify')}
                        className="bg-green-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-green-700">Verify</button>
                      <button onClick={() => handleAction(doc._id, 'reject')}
                        className="bg-red-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-red-700">Reject</button>
                      <button onClick={() => setActionId('')}
                        className="text-gray-500 px-3 py-2 text-sm hover:bg-gray-100 rounded-lg">Cancel</button>
                    </div>
                  ) : (
                    <button onClick={() => setActionId(doc._id)}
                      className="text-sm text-blue-700 hover:underline">Review this document</button>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
