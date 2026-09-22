import { useState, useEffect } from 'react';
import { api } from '../services/api';
import { Card, PageHeader, StatCard, LoadingSpinner, ErrorMessage, PageShell } from '../components/ui';

export function OverviewPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true); setError('');
    try { const res = await api.get('/admin/stats'); setData(res.data); }
    catch (e: any) { setError(e.response?.data?.detail || e.message); }
    finally { setLoading(false); }
  };
  useEffect(() => { load(); }, []);
  if (loading) return <LoadingSpinner message="Loading overview..." />;
  if (error) return <ErrorMessage message={error} onRetry={load} />;

  return (
    <PageShell>
      <PageHeader title="Overview" sub="Platform-wide summary" />
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(170px, 1fr))', gap: 14, marginBottom: 28 }}>
        <StatCard label="Total Students" value={data?.total_students ?? 0} color="#1E3A8A" />
        <StatCard label="Teachers" value={data?.total_teachers ?? 0} color="#3B82F6" />
        <StatCard label="Courses" value={data?.total_courses ?? 0} color="#059669" />
        <StatCard label="Avg Attendance" value={`${data?.avg_attendance ?? 0}%`} color="#D97706" />
        <StatCard label="Docs Pending" value={data?.pending_documents ?? 0} color="#DC2626" />
        <StatCard label="Open Interventions" value={data?.open_interventions ?? 0} color="#7C3AED" />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 14, color: '#0F172A' }}>PROK Identity</h2>
          {['MANAGE', 'GUIDE', 'SUPPORT', 'GROW'].map((tag, i) => (
            <div key={tag} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
              <div style={{ width: 28, height: 28, background: '#EFF6FF', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 700, color: '#1E3A8A' }}>{i + 1}</div>
              <span style={{ fontSize: 14, fontWeight: 600, color: '#1E3A8A' }}>{tag}</span>
            </div>
          ))}
        </Card>
        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 14, color: '#0F172A' }}>Quick Actions</h2>
          {[
            { label: 'Review Pending Documents', path: '/documents', color: '#FEF2F2', text: '#DC2626' },
            { label: 'Check Open Interventions', path: '/interventions', color: '#FEF2F2', text: '#DC2626' },
            { label: 'View AI Insights', path: '/ai-insights', color: '#EFF6FF', text: '#1E3A8A' },
          ].map(({ label, path, color, text }) => (
            <a key={path} href={path} style={{ display: 'block', padding: '10px 14px', background: color, borderRadius: 8, marginBottom: 8, fontSize: 13, fontWeight: 600, color: text, textDecoration: 'none' }}>{label} &rarr;</a>
          ))}
        </Card>
      </div>
    </PageShell>
  );
}
