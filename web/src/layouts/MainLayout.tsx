import { useCallback } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';

const navItems = [
  { to: '/dashboard', label: '🏠 Dashboard' },
  { to: '/attendance', label: '📋 Attendance' },
  { to: '/documents', label: '📂 Documents' },
  { to: '/scholarships', label: '🎓 Scholarships' },
  { to: '/courses', label: '📚 Courses' },
  { to: '/analytics', label: '📊 Analytics' },
];

export default function MainLayout() {
  const navigate = useNavigate();

  const handleLogout = useCallback(() => {
    localStorage.removeItem('prok_token');
    localStorage.removeItem('prok_user');
    navigate('/login');
  }, [navigate]);

  const rawUser = localStorage.getItem('prok_user');
  const user = rawUser ? JSON.parse(rawUser) : null;

  return (
    <div style={{ display: 'flex', height: '100vh', fontFamily: 'system-ui, sans-serif' }}>
      {/* Sidebar */}
      <aside style={{
        width: 240,
        background: '#1a1a2e',
        color: '#fff',
        display: 'flex',
        flexDirection: 'column',
        padding: '24px 0',
      }}>
        <div style={{ padding: '0 24px 24px', borderBottom: '1px solid #2a2a4e' }}>
          <h1 style={{ margin: 0, fontSize: 22, letterSpacing: 2 }}>PROK</h1>
          <p style={{ margin: '4px 0 0', fontSize: 12, color: '#8888bb' }}>Admin Dashboard</p>
        </div>

        <nav style={{ flex: 1, padding: '16px 0' }}>
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              style={({ isActive }) => ({
                display: 'block',
                padding: '10px 24px',
                color: isActive ? '#fff' : '#8888bb',
                background: isActive ? '#2a2a4e' : 'transparent',
                textDecoration: 'none',
                fontSize: 14,
                borderLeft: isActive ? '3px solid #6c63ff' : '3px solid transparent',
              })}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div style={{ padding: '16px 24px', borderTop: '1px solid #2a2a4e' }}>
          {user && <p style={{ margin: '0 0 8px', fontSize: 12, color: '#8888bb' }}>{user.email}</p>}
          <button
            onClick={handleLogout}
            style={{
              width: '100%',
              padding: '8px',
              background: '#c0392b',
              color: '#fff',
              border: 'none',
              borderRadius: 6,
              cursor: 'pointer',
              fontSize: 13,
            }}
          >
            Logout
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main style={{ flex: 1, overflow: 'auto', background: '#f4f6fa', padding: 32 }}>
        <Outlet />
      </main>
    </div>
  );
}
