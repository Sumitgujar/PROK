import { useState, useEffect } from 'react';
import { api } from '../services/api';
import { PageHeader, LoadingSpinner, ErrorMessage, EmptyState, Badge, PageShell, StatCard } from '../components/ui';

export function InterventionsPage() {
  const [interventions, setInterventions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('ALL');
  const [updating, setUpdating] = useState<string | null>(null);

  const load = async () => {
    setLoading(true); setError('');
    try { const res = await api.get('/interventions'); setInterventions(res.data.interventions ?? res.data ?? []); }
    catch (e: any) { setError(e.response?.data?.detail || e.message); }
    finally { setLoading(false); }
  };
  useEffect(() => { load(); }, []);

  const updateStatus = async (id: string, status: string) => {
    if (!window.confirm(`Update intervention status to ${status}?`)) return;
    setUpdating(id);
    try { await api.patch(`/interventions/${id}/status`, { status }); load(); }
    catch (e: any) { alert('Update failed'); }
    finally { setUpdating(null); }
  };

  if (loading) return <LoadingSpinner message="Loading interventions..." />;
  if (error) return <ErrorMessage message={error} onRetry={load} />;

  const filtered = filter === 'ALL' ? interventions : interventions.filter(i => i.status === filter);

  return (
    <PageShell>
      <PageHeader title="Interventions" sub="Track and resolve student support actions" />
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))', gap: 14, marginBottom: 24 }}>
        <StatCard label="Open" value={interventions.filter(i => i.status === 'OPEN').length} color="#DC2626" />
        <StatCard label="In Progress" value={interventions.filter(i => i.status === 'IN_PROGRESS').length} color="#D97706" />
        <StatCard label="Resolved" value={interventions.filter(i => i.status === 'RESOLVED').length} color="#059669" />
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED'].map(s => (
          <button key={s} onClick={() => setFilter(s)}
            style={{ padding: '6px 14px', borderRadius: 8, border: '1px solid', fontSize: 13, fontWeight: 600, cursor: 'pointer',
              background: filter === s ? '#1E3A8A' : '#fff', color: filter === s ? '#fff' : '#64748B', borderColor: filter === s ? '#1E3A8A' : '#E2E8F0' }}>
            {s.replace('_', ' ')}
          </button>
        ))}
      </div>
      {filtered.length === 0 ? <EmptyState title="No interventions" /> : (
        <div style={{ display: 'grid', gap: 8 }}>
          {filtered.map((intv: any) => (
            <div key={intv._id ?? intv.id} style={{ background: '#fff', border: '1px solid #E2E8F0', borderRadius: 12, padding: '14px 18px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600, color: '#0F172A', fontSize: 14 }}>{intv.student_name ?? intv.student_id}</div>
                  <div style={{ fontSize: 13, color: '#64748B', marginTop: 4 }}>{intv.reason ?? intv.intervention_type ?? 'Attendance risk'}</div>
                  <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 4 }}>{(intv.created_at ?? '').slice(0, 10)}</div>
                </div>
                <Badge status={intv.status} />
              </div>
              {intv.status !== 'RESOLVED' && (
                <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                  {intv.status === 'OPEN' && (
                    <button onClick={() => updateStatus(intv._id ?? intv.id, 'IN_PROGRESS')} disabled={updating === (intv._id ?? intv.id)}
                      style={{ padding: '5px 14px', background: '#FFFBEB', color: '#D97706', border: '1px solid #D97706', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Start</button>
                  )}
                  <button onClick={() => updateStatus(intv._id ?? intv.id, 'RESOLVED')} disabled={updating === (intv._id ?? intv.id)}
                    style={{ padding: '5px 14px', background: '#ECFDF5', color: '#059669', border: '1px solid #059669', borderRadius: 6, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Resolve</button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </PageShell>
  );
}
