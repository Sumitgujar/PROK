import { useEffect, useState } from 'react'
import { adminApi } from '../services/admin'

interface Student { _id: string; full_name: string; email: string; college_id: string; department?: string; semester?: number; cgpa?: number; }

export default function StudentsPage() {
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')

  useEffect(() => {
    adminApi.getStudents()
      .then(data => setStudents(Array.isArray(data) ? data : data.students ?? []))
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const filtered = students.filter(s =>
    s.full_name.toLowerCase().includes(search.toLowerCase()) ||
    s.email.toLowerCase().includes(search.toLowerCase()) ||
    (s.college_id ?? '').toLowerCase().includes(search.toLowerCase())
  )

  if (loading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-900" /></div>
  if (error) return <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-lg">Error: {error}</div>

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Students</h1>
      <div className="mb-4">
        <input type="search" placeholder="Search by name, email or ID..."
          value={search} onChange={e => setSearch(e.target.value)}
          className="w-full sm:w-80 border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" />
      </div>
      {filtered.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <div className="text-5xl mb-3">👨‍🎓</div>
          <p className="text-lg font-medium">No students found</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl shadow overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 uppercase text-xs">
              <tr>
                <th className="px-6 py-3 text-left">Student</th>
                <th className="px-6 py-3 text-left">ID</th>
                <th className="px-6 py-3 text-left">Department</th>
                <th className="px-6 py-3 text-left">Semester</th>
                <th className="px-6 py-3 text-left">CGPA</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.map(s => (
                <tr key={s._id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="font-medium text-gray-800">{s.full_name}</div>
                    <div className="text-gray-400 text-xs">{s.email}</div>
                  </td>
                  <td className="px-6 py-4 text-gray-600">{s.college_id}</td>
                  <td className="px-6 py-4 text-gray-600">{s.department || '—'}</td>
                  <td className="px-6 py-4 text-gray-600">{s.semester || '—'}</td>
                  <td className="px-6 py-4">{s.cgpa != null ? s.cgpa.toFixed(2) : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
