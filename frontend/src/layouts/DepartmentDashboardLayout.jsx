import React, { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Building2, LayoutDashboard, AlertCircle, User as UserIcon, LogOut, Menu, X, Bell, Package } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import './layouts.css';

export const DepartmentDashboardLayout = ({ children }) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const isActive = (path) => {
    return location.pathname === path || location.pathname.startsWith(path + '/');
  };

  const navItems = [
    {
      path: '/department/dashboard',
      icon: LayoutDashboard,
      label: 'Dashboard'
    },
    {
      path: '/department/issues',
      icon: AlertCircle,
      label: 'Civic Issues'
    },
    {
      path: '/department/service-requests',
      icon: Package,
      label: 'Service Requests'
    },
    {
      path: '/department/notifications',
      icon: Bell,
      label: 'Notifications'
    },
    {
      path: '/department/profile',
      icon: UserIcon,
      label: 'Profile'
    }
  ];

  return (
    <div className="dashboard-layout">
      {/* Sidebar - matching Citizen width and style */}
      <aside className="dashboard-sidebar">
        <div className="sidebar-header">
          <Link to="/department/dashboard" style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--primary-600)', fontWeight: '700', fontSize: '1.25rem', textDecoration: 'none'}}>
            <Building2 size={24} />
            <div style={{display: 'flex', flexDirection: 'column', gap: '0.125rem'}}>
              <span>CivicPulse</span>
              <span style={{
                fontSize: '0.625rem',
                fontWeight: '600',
                color: 'var(--info-600)',
                backgroundColor: 'var(--info-100)',
                padding: '0.125rem 0.375rem',
                borderRadius: '0.25rem',
                alignSelf: 'flex-start'
              }}>
                DEPARTMENT
              </span>
            </div>
          </Link>
        </div>

        <div className="sidebar-nav">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = isActive(item.path);
            
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`sidebar-link ${active ? 'active' : ''}`}
                onClick={() => setSidebarOpen(false)}
              >
                <Icon size={20} />
                <span>{item.label}</span>
              </Link>
            );
          })}
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

      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && (
        <div 
          className="sidebar-overlay" 
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Main Content - matching Citizen layout */}
      <main className="dashboard-main">
        {/* Top Header - matching Citizen header */}
        <header className="dashboard-header">
          <button 
            className="mobile-menu-btn"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            style={{display: 'none', background: 'transparent', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', padding: '0.5rem'}}
          >
            {sidebarOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
          
          <div style={{fontWeight: '500', color: 'var(--text-secondary)'}}>
            Welcome back, {user?.name}
          </div>
          
          <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
            <button 
              onClick={() => navigate('/department/notifications')}
              style={{background: 'transparent', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer'}}
              title="View notifications"
            >
              <Bell size={20} />
            </button>
            <button
              onClick={() => navigate('/department/profile')}
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

        {/* Page Content */}
        <div className="dashboard-content">
          {children}
        </div>
      </main>
    </div>
  );
};
