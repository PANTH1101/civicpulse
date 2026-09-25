import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../services/api';

const AuthContext = createContext();

export const useAuth = () => {
  return useContext(AuthContext);
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      const token = localStorage.getItem('civicpulse_token');
      if (token) {
        try {
          const data = await api.get('/auth/protected');
          setUser(data.user);
        } catch (error) {
          console.error('Auth check failed:', error);
          localStorage.removeItem('civicpulse_token');
          setUser(null);
        }
      }
      setLoading(false);
    };

    checkAuth();
  }, []);

  const login = async (email, password) => {
    const data = await api.post('/auth/login', { email, password });
    localStorage.setItem('civicpulse_token', data.token);
    setUser(data.user);
    return data;
  };

  const register = async (name, email, password) => {
    return await api.post('/auth/register', { name, email, password, role: 'CITIZEN' });
  };

  const logout = () => {
    localStorage.removeItem('civicpulse_token');
    setUser(null);
  };

  const value = {
    user,
    loading,
    login,
    register,
    logout,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
