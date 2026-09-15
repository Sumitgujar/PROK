import { useEffect, useState } from 'react'
import { coursesApi } from '../services/courses'

interface Course { _id: string; title: string; course_code: string; department: string; credits: number; teacher_name?: string; enrolled_count?: number; is_active: boolean; tags?: string[]; }

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [deptFilter, setDeptFilter] = useState('ALL')

  useEffect(() => {
    coursesApi.getCourses()
      .then(data => setCourses(Array.isArray(data) ? data : data.courses ?? []))
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const depts = ['ALL', ...Array.from(new Set(courses.map(c => c.department).filter(Boolean)))]

  const filtered = courses.filter(c => {
    const matchSearch = !search ||
      c.title.toLowerCase().includes(search.toLowerCase()) ||
      c.course_code.toLowerCase().includes(search.toLowerCase())
    const matchDept = deptFilter === 'ALL' || c.department === deptFilter
    return matchSearch && matchDept
  })

  if (loading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-900" /></div>
  if (error) return <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-lg">Error: {error}</div>

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Courses</h1>
      <div className="flex flex-wrap gap-3 mb-4">
        <input type="search" placeholder="Search courses..."
          value={search} onChange={e => setSearch(e.target.value)}
          className="border border-gray-300 rounded-lg px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 w-64" />
        <select value={deptFilter} onChange={e => setDeptFilter(e.target.value)}
          className="border border-gray-300 rounded-lg px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
          {depts.map(d => <option key={d}>{d}</option>)}
        </select>
      </div>
      {filtered.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <div className="text-5xl mb-3">📚</div>
          <p className="text-lg font-medium">No courses found</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map(c => (
            <div key={c._id} className="bg-white rounded-xl shadow p-5 hover:shadow-md transition">
              <div className="flex items-start justify-between mb-2">
                <span className="text-xs font-bold text-blue-700 bg-blue-50 px-2 py-1 rounded">{c.course_code}</span>
                <span className={`text-xs px-2 py-1 rounded-full ${
                  c.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                  {c.is_active ? 'Active' : 'Inactive'}
                </span>
              </div>
              <h3 className="font-semibold text-gray-800 mt-2">{c.title}</h3>
              <p className="text-sm text-gray-500">{c.department}</p>
              {c.teacher_name && <p className="text-xs text-gray-400 mt-1">{c.teacher_name}</p>}
              <div className="flex items-center gap-4 mt-3 text-xs text-gray-500">
                <span>📊 {c.credits} credits</span>
                {c.enrolled_count != null && <span>👥 {c.enrolled_count} enrolled</span>}
              </div>
              {c.tags && c.tags.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-3">
                  {c.tags.slice(0, 3).map(t => (
                    <span key={t} className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">{t}</span>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
