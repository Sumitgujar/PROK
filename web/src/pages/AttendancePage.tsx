import { useEffect, useState } from 'react'
import { attendanceApi } from '../services/attendance'

interface Session { _id: string; course_title: string; course_code: string; date: string; present: number; absent: number; total: number; }

export default function AttendancePage() {
  const [sessions, setSessions] = useState<Session[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [expanded, setExpanded] = useState<string | null>(null)
  const [records, setRecords] = useState<any[]>([])
  const [loadingRec, setLoadingRec] = useState(false)

  useEffect(() => {
    attendanceApi.getTodaySessions()
      .then(data => setSessions(Array.isArray(data) ? data : data.sessions ?? []))
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const toggleSession = async (id: string) => {
    if (expanded === id) { setExpanded(null); return }
    setExpanded(id)
    setLoadingRec(true)
    try {
      const data = await attendanceApi.getSessionRecords(id)
      setRecords(Array.isArray(data) ? data : data.records ?? [])
    } catch { setRecords([]) }
    finally { setLoadingRec(false) }
  }

  if (loading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-900" /></div>
  if (error) return <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-lg">Error: {error}</div>

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Attendance</h1>
      {sessions.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <div className="text-5xl mb-3">📋</div>
          <p className="text-lg font-medium">No attendance sessions found</p>
        </div>
      ) : (
        <div className="space-y-4">
          {sessions.map(s => (
            <div key={s._id} className="bg-white rounded-xl shadow overflow-hidden">
              <div className="flex items-center justify-between p-5 cursor-pointer hover:bg-gray-50"
                onClick={() => toggleSession(s._id)}>
                <div>
                  <h3 className="font-semibold text-gray-800">{s.course_title}</h3>
                  <p className="text-sm text-gray-500">{s.course_code} • {s.date?.slice(0,10)}</p>
                </div>
                <div className="flex items-center gap-4">
                  <div className="text-center">
                    <div className="text-green-600 font-bold">{s.present}</div>
                    <div className="text-xs text-gray-400">Present</div>
                  </div>
                  <div className="text-center">
                    <div className="text-red-500 font-bold">{s.absent}</div>
                    <div className="text-xs text-gray-400">Absent</div>
                  </div>
                  <div className="text-center">
                    <div className="text-blue-700 font-bold">{s.total > 0 ? Math.round(s.present/s.total*100) : 0}%</div>
                    <div className="text-xs text-gray-400">Rate</div>
                  </div>
                  <svg className={`w-5 h-5 text-gray-400 transition-transform ${expanded===s._id?'rotate-180':''}`}
                    fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </div>
              </div>
              {expanded === s._id && (
                <div className="border-t px-5 pb-4">
                  {loadingRec ? (
                    <div className="py-4 text-center text-gray-400">Loading...</div>
                  ) : records.length === 0 ? (
                    <div className="py-4 text-center text-gray-400">No records</div>
                  ) : (
                    <table className="w-full text-sm mt-3">
                      <thead><tr className="text-gray-400 text-xs uppercase">
                        <th className="text-left py-2">Student</th>
                        <th className="text-left py-2">Status</th>
                        <th className="text-left py-2">Time</th>
                      </tr></thead>
                      <tbody className="divide-y divide-gray-50">
                        {records.map((r,i) => (
                          <tr key={i}>
                            <td className="py-2">{r.student_name || r.student_id}</td>
                            <td className="py-2">
                              <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                                r.status==='present'?'bg-green-100 text-green-700':
                                r.status==='late'?'bg-yellow-100 text-yellow-700':'bg-red-100 text-red-700'}`}>
                                {r.status}
                              </span>
                            </td>
                            <td className="py-2 text-gray-400">{r.marked_at?.slice(11,16)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
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
