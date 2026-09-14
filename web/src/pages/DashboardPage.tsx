import { useEffect, useState } from 'react';
import { healthApi } from '../services/api';

interface HealthData {
  status: string;
  database: string;
  timestamp: number;
}

const modules = [
  { label: 'Attendance', icon: '📋', desc: 'Student & teacher attendance tracking', status: 'Coming in Stage 2' },
  { label: 'Documents', icon: '📂', desc: 'Upload and manage academic documents', status: 'Coming in Stage 2' },
  { label: 'Scholarships', icon: '🎓', desc: 'AI-assisted scholarship matching', status: 'Coming in Stage 2' },
  { label: 'Courses', icon: '📚', desc: 'Personalized course recommendations', status: 'Coming in Stage 2' },
  { label: 'AI Guide', icon: '🤖', desc: 'College AI personal assistant', status: 'Coming in Stage 2' },
  { label: 'Analytics', icon: '📊', desc: 'Admin analytics and verification', status: 'Coming in Stage 2' },
];

export default function DashboardPage() {
  const [health, setHealth] = useState<HealthData | null>(null);
  const rawUser = localStorage.getItem('prok_user');
  const user = rawUser ? JSON.parse(rawUser) : null;

  useEffect(() => {
    healthApi.check().then(setHealth).catch(() => null);
  }, []);

  return (
    <div>
      <h2 style={{ margin: '0 0 4px' }}>Welcome, {user?.name ?? 'User'} 👋</h2>
      <p style={{ color: '#666', margin: '0 0 24px', fontSize: 14 }}>Role: {user?.role}</p>

      {/* Health banner */}
      {health && (
        <div style={{
          background: health.database === 'connected' ? '#eafaf1' : '#fdecea',
          border: `1px solid ${health.database === 'connected' ? '#27ae60' : '#e74c3c'}`,
          borderRadius: 8, padding: '12px 16px', marginBottom: 24, fontSize: 14,
          color: health.database === 'connected' ? '#1e8449' : '#c0392b',
        }}>
          {health.database === 'connected'
            ? '✅ API and MongoDB are connected'
            : `⚠️ Database status: ${health.database}`}
        </div>
      )}

      {/* Module cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: 16 }}>
        {modules.map((m) => (
          <div key={m.label} style={{
            background: '#fff', borderRadius: 10,
            padding: '20px 24px', boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
            borderLeft: '4px solid #6c63ff',
          }}>
            <div style={{ fontSize: 28, marginBottom: 8 }}>{m.icon}</div>
            <h3 style={{ margin: '0 0 6px', fontSize: 16 }}>{m.label}</h3>
            <p style={{ margin: '0 0 10px', fontSize: 13, color: '#666' }}>{m.desc}</p>
            <span style={{
              fontSize: 11, padding: '3px 8px', background: '#eee',
              borderRadius: 20, color: '#888',
            }}>{m.status}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
