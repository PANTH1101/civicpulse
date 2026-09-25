import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Eye, EyeOff, Building2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { Input } from '../components/ui/Input';
import { Button } from '../components/ui/Button';
import './pages.css';

export const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    
    if (!email || !password) {
      setError('Please fill in all fields');
      return;
    }

    setLoading(true);
    try {
      const data = await login(email, password);
      // Route based on role
      if (data.user.role === 'CITIZEN') {
        navigate('/citizen/dashboard');
      } else if (data.user.role === 'MODERATOR') {
        navigate('/moderator/dashboard');
      } else if (data.user.role === 'DEPARTMENT') {
        navigate('/department/dashboard');
      } else {
        navigate('/');
      }
    } catch (err) {
      setError(err.message || 'Failed to log in. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-content">
        <div className="auth-card">
          <div className="auth-header">
            <Link to="/" style={{display: 'inline-flex', alignItems: 'center', gap: '0.5rem', color: 'var(--primary-600)', marginBottom: '1.5rem', textDecoration: 'none'}}>
              <Building2 size={28} />
            </Link>
            <h1 className="auth-title">Welcome Back</h1>
            <p className="auth-subtitle">Log in to access your CivicPulse account</p>
          </div>
          
          {error && (
            <div style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.75rem', borderRadius: 'var(--border-radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem', textAlign: 'center'}}>
              {error}
            </div>
          )}
          
          <form onSubmit={handleSubmit}>
            <Input 
              label="Email Address" 
              type="email" 
              placeholder="Enter your email" 
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            
            <div style={{position: 'relative'}}>
              <Input 
                label="Password" 
                type={showPassword ? 'text' : 'password'} 
                placeholder="Enter your password" 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <button 
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                style={{position: 'absolute', right: '10px', top: '34px', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer'}}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
            
            <Button 
              type="submit" 
              variant="primary" 
              style={{width: '100%', marginTop: '1rem', padding: '0.75rem'}}
              disabled={loading}
            >
              {loading ? 'Logging in...' : 'Log In'}
            </Button>
          </form>
          
          <div style={{marginTop: '2rem', textAlign: 'center', fontSize: '0.875rem'}}>
            <span className="text-secondary">Don't have an account? </span>
            <Link to="/register" style={{fontWeight: '600'}}>Register here</Link>
          </div>
        </div>
      </div>
    </div>
  );
};
