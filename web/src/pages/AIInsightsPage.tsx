import { useState, useEffect } from 'react';
import { api } from '../services/api';
import { PageHeader, LoadingSpinner, ErrorMessage, EmptyState, Badge, PageShell, Card, StatCard } from '../components/ui';

export function AIInsightsPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true); setError('');
    try { const res = await api.get('/intelligence/admin/overview'); setData(res.data); }
    catch (e: any) { setError(e.response?.data?.detail || e.message); }
    finally { setLoading(false); }
  };
  useEffect(() => { load(); }, []);
  if (loading) return <LoadingSpinner message="Loading AI insights..." />;
  if (error) return <ErrorMessage message={error} onRetry={load} />;

  const atRisk = data?.at_risk_students ?? [];
  const matches = data?.scholarship_matches ?? [];

  return (
    <PageShell>
      <PageHeader title="AI Insights" sub="PROK intelligence - MANAGE, GUIDE, SUPPORT, GROW" />
      <div style={{ background: '#EFF6FF', border: '1px solid #BFDBFE', borderRadius: 10, padding: '10px 16px', marginBottom: 24, fontSize: 13, color: '#1E3A8A' }}>
        PROK recommends - humans decide. All insights are based on real student data and rule-based analysis.
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))', gap: 14, marginBottom: 24 }}>
        <StatCard label="High Risk Students" value={atRisk.filter((s: any) => s.risk_level === 'HIGH').length} color="#DC2626" />
        <StatCard label="Medium Risk" value={atRisk.filter((s: any) => s.risk_level === 'MEDIUM').length} color="#D97706" />
        <StatCard label="Scholarship Matches" value={matches.length} color="#059669" />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 14, color: '#0F172A' }}>At-Risk Students</h2>
          {atRisk.length === 0 ? <EmptyState title="No at-risk students" sub="All students on track" /> :
            atRisk.slice(0, 10).map((s: any, i: number) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', borderBottom: '1px solid #F1F5F9' }}>
                <Badge status={s.risk_level ?? 'LOW'} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: '#0F172A' }}>{s.student_name ?? s.student_id}</div>
                  <div style={{ fontSize: 11, color: '#94A3B8' }}>{s.overall_attendance}% attendance</div>
                </div>
              </div>
            ))
          }
        </Card>
        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 14, color: '#0F172A' }}>Scholarship Matches</h2>
          {matches.length === 0 ? <EmptyState title="No matches found" /> :
            matches.slice(0, 8).map((m: any, i: number) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', borderBottom: '1px solid #F1F5F9' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: '#0F172A' }}>{m.student_name ?? m.student_id}</div>
                  <div style={{ fontSize: 11, color: '#94A3B8' }}>{m.scholarship_name}</div>
                </div>
                <span style={{ background: '#ECFDF5', color: '#059669', fontSize: 11, fontWeight: 700, padding: '3px 8px', borderRadius: 999 }}>{m.match_score}%</span>
              </div>
            ))
          }
        </Card>
      </div>
    </PageShell>
  );
}
