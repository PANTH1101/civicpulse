import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from './ProtectedRoute';

// Import pages (we will create these next)
import { Landing } from '../pages/Landing';
import { Login } from '../pages/Login';
import { Register } from '../pages/Register';
import { CitizenDashboard } from '../pages/CitizenDashboard';
import { ReportIssue } from '../pages/ReportIssue';
import { MyIssues } from '../pages/MyIssues';
import { IssueDetails } from '../pages/IssueDetails';
import { MunicipalServices } from '../pages/MunicipalServices';
import { RequestService } from '../pages/RequestService';
import { MyServiceRequests } from '../pages/MyServiceRequests';
import { ServiceRequestDetails } from '../pages/ServiceRequestDetails';
import { Notifications } from '../pages/Notifications';
import { Profile } from '../pages/Profile';
import { PublicNotices } from '../pages/PublicNotices';
import { NoticeDetails } from '../pages/NoticeDetails';
import { ModeratorDashboard } from '../pages/ModeratorDashboard';
import { ModeratorIssues } from '../pages/ModeratorIssues';
import { ModeratorIssueDetails } from '../pages/ModeratorIssueDetails';
import { ModeratorNotifications } from '../pages/ModeratorNotifications';
import { DepartmentDashboard } from '../pages/DepartmentDashboard';
import { DepartmentIssues } from '../pages/DepartmentIssues';
import { DepartmentIssueDetails } from '../pages/DepartmentIssueDetails';
import { DepartmentServiceRequests } from '../pages/DepartmentServiceRequests';
import { DepartmentServiceRequestDetails } from '../pages/DepartmentServiceRequestDetails';
import { DepartmentNotifications } from '../pages/DepartmentNotifications';

export const AppRoutes = () => {
  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/" element={<Landing />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      
      {/* Citizen Protected Routes */}
      <Route 
        path="/citizen/dashboard" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <CitizenDashboard />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/report-issue" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <ReportIssue />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/my-issues" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <MyIssues />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/issues/:id" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <IssueDetails />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/services" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <MunicipalServices />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/services/request" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <RequestService />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/my-requests" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <MyServiceRequests />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/my-requests/:id" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <ServiceRequestDetails />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/notifications" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <Notifications />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/profile" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <Profile />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/notices" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <PublicNotices />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/citizen/notices/:id" 
        element={
          <ProtectedRoute allowedRoles={['CITIZEN']}>
            <NoticeDetails />
          </ProtectedRoute>
        } 
      />
      
      {/* Moderator Protected Routes */}
      <Route 
        path="/moderator/dashboard" 
        element={
          <ProtectedRoute allowedRoles={['MODERATOR']}>
            <ModeratorDashboard />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/moderator/issues" 
        element={
          <ProtectedRoute allowedRoles={['MODERATOR']}>
            <ModeratorIssues />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/moderator/issues/:id" 
        element={
          <ProtectedRoute allowedRoles={['MODERATOR']}>
            <ModeratorIssueDetails />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/moderator/notifications" 
        element={
          <ProtectedRoute allowedRoles={['MODERATOR']}>
            <ModeratorNotifications />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/moderator/profile" 
        element={
          <ProtectedRoute allowedRoles={['MODERATOR']}>
            <Profile />
          </ProtectedRoute>
        } 
      />
      
      {/* Fallback routes for other roles to be implemented later */}
      <Route 
        path="/moderator/*" 
        element={
          <ProtectedRoute allowedRoles={['MODERATOR']}>
            <Navigate to="/moderator/dashboard" replace />
          </ProtectedRoute>
        } 
      />
      
      {/* Department Protected Routes */}
      <Route 
        path="/department/dashboard" 
        element={
          <ProtectedRoute allowedRoles={['DEPARTMENT']}>
            <DepartmentDashboard />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/department/issues" 
        element={
          <ProtectedRoute allowedRoles={['DEPARTMENT']}>
            <DepartmentIssues />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/department/issues/:id" 
        element={
          <ProtectedRoute allowedRoles={['DEPARTMENT']}>
            <DepartmentIssueDetails />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/department/service-requests" 
        element={
          <ProtectedRoute allowedRoles={['DEPARTMENT']}>
            <DepartmentServiceRequests />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/department/service-requests/:id" 
        element={
          <ProtectedRoute allowedRoles={['DEPARTMENT']}>
            <DepartmentServiceRequestDetails />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/department/notifications" 
        element={
          <ProtectedRoute allowedRoles={['DEPARTMENT']}>
            <DepartmentNotifications />
          </ProtectedRoute>
        } 
      />
      <Route 
        path="/department/profile" 
        element={
          <ProtectedRoute allowedRoles={['DEPARTMENT']}>
            <Profile />
          </ProtectedRoute>
        } 
      />
      
      {/* Fallback route for department */}
      <Route 
        path="/department/*" 
        element={
          <ProtectedRoute allowedRoles={['DEPARTMENT']}>
            <Navigate to="/department/dashboard" replace />
          </ProtectedRoute>
        } 
      />
      
      {/* Catch all */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};
