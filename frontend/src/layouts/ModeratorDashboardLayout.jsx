import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Building2, LayoutDashboard, AlertCircle, User, LogOut, Bell } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import './layouts.css';

export const ModeratorDashboardLayout = ({ children }) => {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="dashboard-layout">
      {/* Sidebar */}
      <aside className="dashboard-sidebar">
        <div className="sidebar-header">
          <Link to="/" style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--primary-600)', fontWeight: '700', fontSize: '1.25rem', textDecoration: 'none'}}>
            <Building2 size={24} />
            <div style={{display: 'flex', flexDirection: 'column', gap: '0.125rem'}}>
              <span>CivicPulse</span>
              <span style={{
                fontSize: '0.625rem',
                fontWeight: '600',
                color: 'var(--text-secondary)',
                backgroundColor: 'var(--bg-secondary)',
                padding: '0.125rem 0.375rem',
                borderRadius: '0.25rem',
                alignSelf: 'flex-start'
              }}>
                MODERATOR
              </span>
            </div>
          </Link>
        </div>
        
        <div className="sidebar-nav">
          <Link 
            to="/moderator/dashboard" 
            className={`sidebar-link ${location.pathname === '/moderator/dashboard' ? 'active' : ''}`}
          >
            <LayoutDashboard size={20} />
            Dashboard
          </Link>
          <Link 
            to="/moderator/issues" 
            className={`sidebar-link ${location.pathname.includes('/moderator/issues') ? 'active' : ''}`}
          >
            <AlertCircle size={20} />
            Civic Issues
          </Link>
          <Link 
            to="/moderator/notifications" 
            className={`sidebar-link ${location.pathname.includes('/moderator/notifications') ? 'active' : ''}`}
          >
            <Bell size={20} />
            Notifications
          </Link>
          <Link to="/moderator/profile" className={`sidebar-link ${location.pathname.includes('/moderator/profile') ? 'active' : ''}`}>
            <User size={20} />
            Profile
          </Link>
        </div>
        
        <div className="sidebar-footer">
          <button 
            onClick={handleLogout}
            style={{display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'transparent', border: 'none', color: 'var(--danger-600)', fontWeight: '500', cursor: 'pointer', width: '100%', padding: '0.5rem 0'}}
          >
            <LogOut size={20} />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="dashboard-main">
        <header className="dashboard-header">
          <div>
            <div style={{fontWeight: '500', color: 'var(--text-secondary)'}}>
              Welcome back, {user?.name}
            </div>
            <div style={{fontSize: '0.75rem', color: 'var(--text-tertiary)', marginTop: '0.125rem'}}>
              Moderator Portal
            </div>
          </div>
          <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
            <button 
              onClick={() => navigate('/moderator/notifications')}
              style={{background: 'transparent', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer'}}
              title="View notifications"
            >
              <Bell size={20} />
            </button>
            <button
              onClick={() => navigate('/moderator/profile')}
              style={{
                width: '32px', 
                height: '32px', 
                borderRadius: '50%', 
                backgroundColor: 'var(--primary-100)', 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center', 
                color: 'var(--primary-700)', 
                fontWeight: '600',
                border: 'none',
                cursor: 'pointer'
              }}
              title="View profile"
            >
              {user?.name?.charAt(0).toUpperCase()}
            </button>
          </div>
        </header>
        
        <div className="dashboard-content">
          {children}
        </div>
      </main>
    </div>
  );
};
