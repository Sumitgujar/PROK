import { useState, FormEvent } from 'react'
import { useAuth } from '../hooks/useAuth'
import { useNavigate } from 'react-router-dom'

export default function LoginPage() {
  const { login } = useAuth()
  const nav = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')
    if (!email.trim()) { setError('Email is required'); return }
    if (!password) { setError('Password is required'); return }
    setLoading(true)
    try {
      await login(email.trim(), password)
      nav('/dashboard')
    } catch (err: any) {
      setError(err.message || 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-900 to-blue-600 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl p-8 w-full max-w-md">
        <div className="text-center mb-8">
          <div className="text-5xl mb-2">🎓</div>
          <h1 className="text-3xl font-bold text-blue-900">PROK Admin</h1>
          <p className="text-gray-500 mt-1">College Ecosystem Management</p>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input
              type="email" value={email} onChange={e => setEmail(e.target.value)}
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="admin@prok.edu" autoFocus />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input
              type="password" value={password} onChange={e => setPassword(e.target.value)}
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="••••••••" />
          </div>
          <button
            type="submit" disabled={loading}
            className="w-full bg-blue-900 text-white py-3 rounded-lg font-semibold hover:bg-blue-800 disabled:opacity-60 transition">
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>
        <p className="text-center text-xs text-gray-400 mt-6">Admin access only</p>
      </div>
    </div>
  )
}
