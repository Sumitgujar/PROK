import { useState, FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { authApi } from '../services/api';

export default function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await authApi.login(email, password);
      localStorage.setItem('prok_token', res.access_token);
      localStorage.setItem('prok_user', JSON.stringify(res.user));
      navigate('/dashboard');
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ??
        'Login failed. Check your credentials.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#1a1a2e',
    }}>
      <form
        onSubmit={handleSubmit}
        style={{
          background: '#fff',
          padding: 40,
          borderRadius: 12,
          width: 360,
          boxShadow: '0 8px 32px rgba(0,0,0,0.3)',
        }}
      >
        <h2 style={{ margin: '0 0 8px', color: '#1a1a2e' }}>PROK</h2>
        <p style={{ margin: '0 0 24px', color: '#666', fontSize: 14 }}>Sign in to your account</p>

        {error && (
          <div style={{
            background: '#fdecea', color: '#c0392b', padding: '10px 14px',
            borderRadius: 6, marginBottom: 16, fontSize: 14,
          }}>
            {error}
          </div>
        )}

        <label style={{ display: 'block', marginBottom: 4, fontSize: 13, fontWeight: 600 }}>Email</label>
        <input
          type="email" value={email} required
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@college.edu"
          style={inputStyle}
        />

        <label style={{ display: 'block', margin: '16px 0 4px', fontSize: 13, fontWeight: 600 }}>Password</label>
        <input
          type="password" value={password} required
          onChange={(e) => setPassword(e.target.value)}
          placeholder="••••••••"
          style={inputStyle}
        />

        <button
          type="submit" disabled={loading}
          style={{
            marginTop: 24, width: '100%', padding: '12px',
            background: loading ? '#999' : '#6c63ff',
            color: '#fff', border: 'none', borderRadius: 8,
            fontSize: 15, cursor: loading ? 'not-allowed' : 'pointer', fontWeight: 600,
          }}
        >
          {loading ? 'Signing in…' : 'Sign In'}
        </button>
      </form>
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  width: '100%', padding: '10px 12px', border: '1px solid #ddd',
  borderRadius: 6, fontSize: 14, boxSizing: 'border-box',
};
