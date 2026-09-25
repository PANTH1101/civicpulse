import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Building2, LogOut, User } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { Button } from '../components/ui/Button';
import './layouts.css';

export const Navbar = () => {
  const { isAuthenticated, logout, user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const handleNavClick = (e, sectionId) => {
    e.preventDefault();
    
    // If not on landing page, navigate there first
    if (location.pathname !== '/') {
      navigate('/');
      // Wait for navigation, then scroll
      setTimeout(() => {
        const element = document.getElementById(sectionId);
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      }, 100);
    } else {
      // Already on landing page, just scroll
      const element = document.getElementById(sectionId);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    }
  };

  const getDashboardPath = () => {
    if (!user?.role) return '/citizen/dashboard';
    
    switch (user.role) {
      case 'MODERATOR':
        return '/moderator/dashboard';
      case 'DEPARTMENT':
        return '/department/dashboard';
      case 'CITIZEN':
      default:
        return '/citizen/dashboard';
    }
  };

  const getProfilePath = () => {
    if (!user?.role) return '/citizen/profile';
    
    switch (user.role) {
      case 'MODERATOR':
        return '/moderator/profile';
      case 'DEPARTMENT':
        return '/department/profile';
      case 'CITIZEN':
      default:
        return '/citizen/profile';
    }
  };

  return (
    <nav className="navbar">
      <div className="container navbar-container">
        <Link to="/" className="navbar-brand">
          <Building2 size={24} />
          <span>CivicPulse</span>
        </Link>
        
        <div className="navbar-nav">
          <a href="#home" onClick={(e) => handleNavClick(e, 'home')} className="nav-link">Home</a>
          <a href="#services" onClick={(e) => handleNavClick(e, 'services')} className="nav-link">Services</a>
          <a href="#about" onClick={(e) => handleNavClick(e, 'about')} className="nav-link">About</a>
        </div>
        
        <div className="nav-actions">
          {isAuthenticated ? (
            <>
              <button
                onClick={() => navigate(getProfilePath())}
                className="nav-link"
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: '0.5rem',
                  color: 'inherit',
                  fontSize: 'inherit',
                  fontFamily: 'inherit'
                }}
                title="View profile"
              >
                <User size={16} /> {user?.name}
              </button>
              <Button variant="outline" onClick={() => navigate(getDashboardPath())}>
                Dashboard
              </Button>
              <Button variant="secondary" onClick={handleLogout} style={{padding: '0.5rem'}} title="Logout">
                <LogOut size={16} />
              </Button>
            </>
          ) : (
            <>
              <Link to="/login">
                <Button variant="outline">Login</Button>
              </Link>
              <Link to="/register">
                <Button variant="primary">Register</Button>
              </Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
};
