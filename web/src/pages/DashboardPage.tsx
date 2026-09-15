import { useEffect, useState } from 'react'
import { adminApi } from '../services/admin'

interface Stats { total_students: number; total_courses: number; total_documents: number; pending_documents: number; total_scholarships: number; pending_scholarship_applications: number; }

function StatCard({ label, value, icon, color }: { label: string; value: number; icon: string; color: string }) {
  return (
    <div className={`bg-white rounded-xl shadow p-6 border-l-4 ${color}`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-gray-500 text-sm">{label}</p>
          <p className="text-3xl font-bold text-gray-800 mt-1">{value.toLocaleString()}</p>
        </div>
        <span className="text-4xl">{icon}</span>
      </div>
    </div>
  )
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    adminApi.getStats()
      .then(setStats)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  if (loading) return (
    <div className="flex items-center justify-center h-64">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-900" />
    </div>
  )
  if (error) return (
    <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-lg">
      Error loading dashboard: {error}
    </div>
  )
  if (!stats) return null

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <StatCard label="Total Students" value={stats.total_students} icon="👨‍🎓" color="border-blue-500" />
        <StatCard label="Total Courses" value={stats.total_courses} icon="📚" color="border-green-500" />
        <StatCard label="Total Documents" value={stats.total_documents} icon="📄" color="border-purple-500" />
        <StatCard label="Pending Documents" value={stats.pending_documents} icon="⏳" color="border-yellow-500" />
        <StatCard label="Scholarships" value={stats.total_scholarships} icon="🎓" color="border-pink-500" />
        <StatCard label="Pending Applications" value={stats.pending_scholarship_applications} icon="📋" color="border-orange-500" />
      </div>
    </div>
  )
}
