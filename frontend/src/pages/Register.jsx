import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Eye, EyeOff, Building2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { Input } from '../components/ui/Input';
import { Button } from '../components/ui/Button';
import './pages.css';

export const Register = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  
  const { register } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    
    if (!name || !email || !password || !confirmPassword) {
      setError('Please fill in all fields');
      return;
    }
    
    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);
    try {
      await register(name, email, password);
      setSuccess(true);
      setTimeout(() => {
        navigate('/login');
      }, 2000);
    } catch (err) {
      setError(err.message || 'Failed to register account.');
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
            <h1 className="auth-title">Create Account</h1>
            <p className="auth-subtitle">Join CivicPulse as a Citizen</p>
          </div>
          
          {error && (
            <div style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.75rem', borderRadius: 'var(--border-radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem', textAlign: 'center'}}>
              {error}
            </div>
          )}
          
          {success && (
            <div style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.75rem', borderRadius: 'var(--border-radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem', textAlign: 'center'}}>
              Registration successful! Redirecting to login...
            </div>
          )}
          
          <form onSubmit={handleSubmit}>
            <Input 
              label="Full Name" 
              type="text" 
              placeholder="Enter your name" 
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
            
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
                placeholder="Create a password" 
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
            
            <div style={{position: 'relative'}}>
              <Input 
                label="Confirm Password" 
                type={showPassword ? 'text' : 'password'} 
                placeholder="Confirm your password" 
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
              />
            </div>
            
            <Button 
              type="submit" 
              variant="primary" 
              style={{width: '100%', marginTop: '1rem', padding: '0.75rem'}}
              disabled={loading || success}
            >
              {loading ? 'Creating Account...' : 'Register'}
            </Button>
          </form>
          
          <div style={{marginTop: '2rem', textAlign: 'center', fontSize: '0.875rem'}}>
            <span className="text-secondary">Already have an account? </span>
            <Link to="/login" style={{fontWeight: '600'}}>Log in</Link>
          </div>
        </div>
      </div>
    </div>
  );
};
