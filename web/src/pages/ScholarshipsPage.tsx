import { useEffect, useState } from 'react'
import { adminApi } from '../services/admin'

interface App { _id: string; scholarship_name: string; student_name: string; status: string; applied_at: string; missing_docs: string[]; review_note?: string; }

const statusColor: Record<string, string> = {
  pending: 'bg-yellow-100 text-yellow-700',
  approved: 'bg-green-100 text-green-700',
  rejected: 'bg-red-100 text-red-700',
}

export default function ScholarshipsPage() {
  const [apps, setApps] = useState<App[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [filter, setFilter] = useState('all')
  const [reviewNote, setReviewNote] = useState('')
  const [actionId, setActionId] = useState('')

  const load = () => {
    setLoading(true)
    adminApi.getScholarshipApplications()
      .then(data => setApps(Array.isArray(data) ? data : data.applications ?? []))
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  const handleReview = async (id: string, status: 'approved' | 'rejected') => {
    try {
      await adminApi.reviewScholarshipApplication(id, status, reviewNote)
      setReviewNote('')
      setActionId('')
      load()
    } catch (e: any) { alert(e.message) }
  }

  const filtered = filter === 'all' ? apps : apps.filter(a => a.status === filter)

  if (loading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-900" /></div>
  if (error) return <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-lg">Error: {error}</div>

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Scholarship Applications</h1>
      <div className="flex gap-2 mb-4">
        {['all','pending','approved','rejected'].map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition capitalize ${
              filter === f ? 'bg-blue-900 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {f}
          </button>
        ))}
      </div>
      {filtered.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <div className="text-5xl mb-3">🎓</div>
          <p className="text-lg font-medium">No applications found</p>
        </div>
      ) : (
        <div className="space-y-4">
          {filtered.map(app => (
            <div key={app._id} className="bg-white rounded-xl shadow p-5">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-semibold text-gray-800">{app.scholarship_name}</h3>
                  <p className="text-sm text-gray-500">{app.student_name}</p>
                  <p className="text-xs text-gray-400 mt-1">{app.applied_at?.slice(0,10)}</p>
                  {app.missing_docs?.length > 0 && (
                    <p className="text-xs text-red-500 mt-1">Missing docs: {app.missing_docs.join(', ')}</p>
                  )}
                  {app.review_note && <p className="text-xs text-gray-500 mt-1">Note: {app.review_note}</p>}
                </div>
                <span className={`text-xs font-semibold px-3 py-1 rounded-full capitalize ${statusColor[app.status] ?? 'bg-gray-100 text-gray-600'}`}>
                  {app.status}
                </span>
              </div>
              {app.status === 'pending' && (
                <div className="mt-4 border-t pt-4">
                  {actionId === app._id ? (
                    <div className="flex gap-2">
                      <input value={reviewNote} onChange={e => setReviewNote(e.target.value)}
                        className="flex-1 border rounded-lg px-3 py-2 text-sm" placeholder="Review note (optional)" />
                      <button onClick={() => handleReview(app._id, 'approved')}
                        className="bg-green-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-green-700">Approve</button>
                      <button onClick={() => handleReview(app._id, 'rejected')}
                        className="bg-red-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-red-700">Reject</button>
                      <button onClick={() => setActionId('')}
                        className="text-gray-500 px-3 py-2 text-sm hover:bg-gray-100 rounded-lg">Cancel</button>
                    </div>
                  ) : (
                    <button onClick={() => setActionId(app._id)}
                      className="text-sm text-blue-700 hover:underline">Review application</button>
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
