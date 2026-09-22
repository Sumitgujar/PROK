import { useState, useEffect } from 'react';
import { api } from '../services/api';
import { PageHeader, LoadingSpinner, ErrorMessage, PageShell, Card, StatCard } from '../components/ui';

export function ReportsPage() {
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
  if (loading) return <LoadingSpinner message="Loading reports..." />;
  if (error) return <ErrorMessage message={error} onRetry={load} />;

  return (
    <PageShell>
      <PageHeader title="Reports" sub="Platform health and analytics summary" />
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: 14, marginBottom: 28 }}>
        <StatCard label="Students" value={data?.total_students ?? 0} />
        <StatCard label="Courses" value={data?.total_courses ?? 0} color="#059669" />
        <StatCard label="Avg Attendance" value={`${data?.avg_attendance ?? 0}%`} color="#D97706" />
        <StatCard label="At Risk" value={data?.at_risk_count ?? 0} color="#DC2626" />
        <StatCard label="Scholarships" value={data?.total_scholarships ?? 0} color="#7C3AED" />
        <StatCard label="Verified Docs" value={data?.verified_documents ?? 0} color="#059669" />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 14 }}>Platform Status</h2>
          {[
            { label: 'Backend', value: 'Operational' },
            { label: 'Intelligence Engine', value: 'Active' },
            { label: 'Ask PROK', value: 'Online' },
            { label: 'Document Processing', value: 'Active' },
          ].map(({ label, value }) => (
            <div key={label} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #F1F5F9', fontSize: 14 }}>
              <span style={{ color: '#475569' }}>{label}</span>
              <span style={{ color: '#059669', fontWeight: 600 }}>{value}</span>
            </div>
          ))}
        </Card>
        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 14 }}>PROK Mission</h2>
          {['MANAGE', 'GUIDE', 'SUPPORT', 'GROW'].map((tag, i) => (
            <div key={tag} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', borderBottom: '1px solid #F1F5F9' }}>
              <div style={{ width: 24, height: 24, background: '#EFF6FF', borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 700, color: '#1E3A8A' }}>{i + 1}</div>
              <span style={{ fontSize: 14, fontWeight: 600, color: '#1E3A8A' }}>{tag}</span>
            </div>
          ))}
        </Card>
      </div>
    </PageShell>
  );
}
