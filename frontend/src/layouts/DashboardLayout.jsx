import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Building2, LayoutDashboard, AlertCircle, FileText, Bell, LogOut, User, Megaphone } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import './layouts.css';

export const DashboardLayout = ({ children }) => {
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
            <span>CivicPulse</span>
          </Link>
        </div>
        
        <div className="sidebar-nav">
          <Link 
            to="/citizen/dashboard" 
            className={`sidebar-link ${location.pathname === '/citizen/dashboard' ? 'active' : ''}`}
          >
            <LayoutDashboard size={20} />
            Dashboard
          </Link>
          <Link 
            to="/citizen/my-issues" 
            className={`sidebar-link ${location.pathname.includes('/citizen/my-issues') || location.pathname.includes('/citizen/issues') || location.pathname.includes('/citizen/report-issue') ? 'active' : ''}`}
          >
            <AlertCircle size={20} />
            My Issues
          </Link>
          <Link 
            to="/citizen/services" 
            className={`sidebar-link ${location.pathname.includes('/citizen/services') ? 'active' : ''}`}
          >
            <FileText size={20} />
            Municipal Services
          </Link>
          <Link to="/citizen/my-requests" className={`sidebar-link ${location.pathname.includes('/citizen/my-requests') ? 'active' : ''}`}>
            <FileText size={20} />
            Service Requests
          </Link>
          <Link to="/citizen/notices" className={`sidebar-link ${location.pathname.includes('/citizen/notices') ? 'active' : ''}`}>
            <Megaphone size={20} />
            Public Notices
          </Link>
          <Link to="/citizen/notifications" className={`sidebar-link ${location.pathname.includes('/citizen/notifications') ? 'active' : ''}`}>
            <Bell size={20} />
            Notifications
          </Link>
          <Link to="/citizen/profile" className={`sidebar-link ${location.pathname.includes('/citizen/profile') ? 'active' : ''}`}>
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
          <div style={{fontWeight: '500', color: 'var(--text-secondary)'}}>
            Welcome back, {user?.name}
          </div>
          <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
            <button 
              onClick={() => navigate('/citizen/notifications')}
              style={{background: 'transparent', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer'}}
              title="View notifications"
            >
              <Bell size={20} />
            </button>
            <button
              onClick={() => navigate('/citizen/profile')}
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
