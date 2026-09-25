import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export const ProtectedRoute = ({ children, allowedRoles = [] }) => {
  const { user, isAuthenticated, loading } = useAuth();

  if (loading) {
    return <div style={{display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh'}}>Loading...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles.length > 0 && !allowedRoles.includes(user?.role)) {
    // If authenticated but wrong role
    if (user?.role === 'MODERATOR') return <Navigate to="/moderator/dashboard" replace />;
    if (user?.role === 'DEPARTMENT') return <Navigate to="/department/dashboard" replace />;
    return <Navigate to="/citizen/dashboard" replace />;
  }

  return children;
};
