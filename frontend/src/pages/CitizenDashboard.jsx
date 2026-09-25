import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { AlertCircle, FileText, CheckCircle2, Clock, Plus, Inbox, Bell, AlertTriangle } from 'lucide-react';
import { api } from '../services/api';
import './pages.css';

export const CitizenDashboard = () => {
  const navigate = useNavigate();
  
  const [issues, setIssues] = useState([]);
  const [issuesLoading, setIssuesLoading] = useState(true);
  const [issuesError, setIssuesError] = useState('');

  const [serviceRequests, setServiceRequests] = useState([]);
  const [requestsLoading, setRequestsLoading] = useState(true);
  const [requestsError, setRequestsError] = useState('');

  const [notifications, setNotifications] = useState([]);
  const [notifsLoading, setNotifsLoading] = useState(true);
  const [notifsError, setNotifsError] = useState('');

  const fetchIssues = async () => {
    setIssuesLoading(true);
    setIssuesError('');
    try {
      const res = await api.get('/issues/my-issues');
      // The backend returns { issues: [...] }
      setIssues(res.issues || []);
    } catch (error) {
      setIssuesError('Unable to load your issues.');
    } finally {
      setIssuesLoading(false);
    }
  };

  const fetchRequests = async () => {
    setRequestsLoading(true);
    setRequestsError('');
    try {
      const res = await api.get('/services/requests/my');
      // The backend returns { serviceRequests: [...] }
      setServiceRequests(res.serviceRequests || []);
    } catch (error) {
      setRequestsError('Unable to load your service requests.');
    } finally {
      setRequestsLoading(false);
    }
  };

  const fetchNotifications = async () => {
    setNotifsLoading(true);
    setNotifsError('');
    try {
      const res = await api.get('/notifications');
      // The backend returns { notifications: [...] }
      setNotifications(res.notifications || []);
    } catch (error) {
      setNotifsError('Unable to load notifications.');
    } finally {
      setNotifsLoading(false);
    }
  };

  useEffect(() => {
    fetchIssues();
    fetchRequests();
    fetchNotifications();
  }, []);

  const getIssueStatusBadge = (status) => {
    switch (status) {
      case 'REPORTED': return <Badge variant="warning">Reported</Badge>;
      case 'ASSIGNED': return <Badge variant="primary">Assigned</Badge>;
      case 'IN_PROGRESS': return <Badge variant="primary">In Progress</Badge>;
      case 'RESOLVED': return <Badge variant="success">Resolved</Badge>;
      case 'REJECTED': return <Badge variant="danger">Rejected</Badge>;
      default: return <Badge>{status}</Badge>;
    }
  };

  const getServiceStatusBadge = (status) => {
    switch (status) {
      case 'PENDING': return <Badge variant="warning">Pending</Badge>;
      case 'ACCEPTED': return <Badge variant="primary">Accepted</Badge>;
      case 'IN_PROGRESS': return <Badge variant="primary">In Progress</Badge>;
      case 'COMPLETED': return <Badge variant="success">Completed</Badge>;
      case 'REJECTED': return <Badge variant="danger">Rejected</Badge>;
      case 'CANCELLED': return <Badge variant="default">Cancelled</Badge>;
      default: return <Badge>{status}</Badge>;
    }
  };

  const inProgressIssuesCount = issues.filter(i => i.status === 'ASSIGNED' || i.status === 'IN_PROGRESS').length;
  const resolvedIssuesCount = issues.filter(i => i.status === 'RESOLVED').length;

  return (
    <DashboardLayout>
      {/* Summary Cards */}
      <div className="dashboard-grid" style={{marginBottom: '2rem'}}>
        <Card className="stat-card" style={{padding: '1.25rem'}}>
          <div className="stat-icon warning" style={{width: '2.75rem', height: '2.75rem', flexShrink: 0}}>
            <AlertCircle size={22} />
          </div>
          <div className="stat-info">
            <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{issuesLoading ? '...' : issues.length}</h3>
            <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Total Issues</p>
          </div>
        </Card>
        
        <Card className="stat-card" style={{padding: '1.25rem'}}>
          <div className="stat-icon primary" style={{width: '2.75rem', height: '2.75rem', flexShrink: 0}}>
            <Clock size={22} />
          </div>
          <div className="stat-info">
            <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{issuesLoading ? '...' : inProgressIssuesCount}</h3>
            <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>In Progress</p>
          </div>
        </Card>
        
        <Card className="stat-card" style={{padding: '1.25rem'}}>
          <div className="stat-icon success" style={{width: '2.75rem', height: '2.75rem', flexShrink: 0}}>
            <CheckCircle2 size={22} />
          </div>
          <div className="stat-info">
            <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{issuesLoading ? '...' : resolvedIssuesCount}</h3>
            <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Resolved Issues</p>
          </div>
        </Card>
        
        <Card className="stat-card" style={{padding: '1.25rem'}}>
          <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', flexShrink: 0, backgroundColor: 'var(--secondary-100)', color: 'var(--secondary-800)'}}>
            <FileText size={22} />
          </div>
          <div className="stat-info">
            <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{requestsLoading ? '...' : serviceRequests.length}</h3>
            <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Service Requests</p>
          </div>
        </Card>
      </div>

      <div className="dashboard-sections">
        {/* Main Content Area */}
        <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
          
          {/* Recent Issues */}
          <Card style={{padding: '1.5rem'}}>
            <div className="section-header" style={{marginBottom: '1.25rem'}}>
              <h2 style={{fontSize: '1.125rem', fontWeight: '600', margin: 0, color: 'var(--text-primary)'}}>Recent Civic Issues</h2>
              <Button variant="outline" style={{padding: '0.5rem 1rem', display: 'flex', alignItems: 'center', gap: '0.5rem'}} onClick={() => navigate('/citizen/report-issue')}>
                <Plus size={16} />
                Report Issue
              </Button>
            </div>
            
            {issuesLoading ? (
              <div style={{padding: '2rem', textAlign: 'center', color: 'var(--text-secondary)'}}>
                Loading issues...
              </div>
            ) : issuesError ? (
              <div style={{padding: '2rem', textAlign: 'center', color: 'var(--danger-600)'}}>
                <AlertTriangle size={32} style={{margin: '0 auto 1rem'}} />
                <p>{issuesError}</p>
                <Button variant="outline" onClick={fetchIssues} style={{marginTop: '1rem'}}>Retry</Button>
              </div>
            ) : issues.length > 0 ? (
              <div style={{display: 'flex', flexDirection: 'column'}}>
                {issues.slice(0, 5).map(issue => (
                  <div key={issue.id} className="list-item">
                    <div className="list-item-content">
                      <h4>{issue.title}</h4>
                      <p>{issue.category} • {new Date(issue.createdAt).toLocaleDateString()}</p>
                    </div>
                    <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
                      {getIssueStatusBadge(issue.status)}
                      <Button variant="outline" style={{padding: '0.25rem 0.75rem', fontSize: '0.75rem'}} onClick={() => navigate(`/citizen/issues/${issue.id}`)}>View</Button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="empty-state" style={{padding: '3rem 1.5rem'}}>
                <Inbox size={40} style={{color: 'var(--text-tertiary)', marginBottom: '1rem'}} />
                <h3 style={{fontSize: '1rem', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)'}}>No issues reported</h3>
                <p style={{margin: '0 0 1.5rem 0', fontSize: '0.875rem', color: 'var(--text-secondary)'}}>You haven't reported any civic issues yet.</p>
                <Button variant="primary" onClick={() => navigate('/citizen/report-issue')}>Report an Issue</Button>
              </div>
            )}
          </Card>

          {/* Service Requests */}
          <Card style={{padding: '1.5rem'}}>
            <div className="section-header" style={{marginBottom: '1.25rem'}}>
              <h2 style={{fontSize: '1.125rem', fontWeight: '600', margin: 0, color: 'var(--text-primary)'}}>Recent Service Requests</h2>
              <Button variant="outline" style={{padding: '0.5rem 1rem'}} onClick={() => navigate('/citizen/services')}>
                Browse Services
              </Button>
            </div>
            
            {requestsLoading ? (
              <div style={{padding: '2rem', textAlign: 'center', color: 'var(--text-secondary)'}}>
                Loading service requests...
              </div>
            ) : requestsError ? (
              <div style={{padding: '2rem', textAlign: 'center', color: 'var(--danger-600)'}}>
                <AlertTriangle size={32} style={{margin: '0 auto 1rem'}} />
                <p>{requestsError}</p>
                <Button variant="outline" onClick={fetchRequests} style={{marginTop: '1rem'}}>Retry</Button>
              </div>
            ) : serviceRequests.length > 0 ? (
              <div style={{display: 'flex', flexDirection: 'column'}}>
                {serviceRequests.slice(0, 5).map(request => (
                  <div key={request.id} className="list-item">
                    <div className="list-item-content">
                      <h4>{request.service?.name || 'Service Request'}</h4>
                      <p>{request.department?.name || 'Department'} • {new Date(request.createdAt).toLocaleDateString()}</p>
                    </div>
                    <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
                      {getServiceStatusBadge(request.status)}
                      <Button variant="outline" style={{padding: '0.25rem 0.75rem', fontSize: '0.75rem'}} onClick={() => navigate(`/citizen/my-requests/${request.id}`)}>View</Button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="empty-state" style={{padding: '3rem 1.5rem'}}>
                <FileText size={40} style={{color: 'var(--text-tertiary)', marginBottom: '1rem'}} />
                <h3 style={{fontSize: '1rem', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)'}}>No service requests</h3>
                <p style={{margin: '0 0 1.5rem 0', fontSize: '0.875rem', color: 'var(--text-secondary)'}}>You haven't submitted any service requests yet.</p>
                <Button variant="primary" onClick={() => navigate('/citizen/services')}>Browse Services</Button>
              </div>
            )}
          </Card>
        </div>

        {/* Sidebar Area */}
        <div>
          <Card style={{padding: '1.5rem'}}>
            <div className="section-header" style={{marginBottom: '1.25rem'}}>
              <h2 style={{fontSize: '1.125rem', fontWeight: '600', margin: 0, color: 'var(--text-primary)'}}>Notifications</h2>
            </div>
            
            {notifsLoading ? (
              <div style={{padding: '2rem', textAlign: 'center', color: 'var(--text-secondary)'}}>
                Loading notifications...
              </div>
            ) : notifsError ? (
              <div style={{padding: '2rem', textAlign: 'center', color: 'var(--danger-600)'}}>
                <AlertTriangle size={32} style={{margin: '0 auto 1rem'}} />
                <p>{notifsError}</p>
                <Button variant="outline" onClick={fetchNotifications} style={{marginTop: '1rem'}}>Retry</Button>
              </div>
            ) : notifications.length > 0 ? (
              <div style={{display: 'flex', flexDirection: 'column'}}>
                {notifications.slice(0, 5).map(notif => (
                  <div key={notif.id} className="list-item" style={{backgroundColor: notif.is_read ? 'transparent' : 'var(--primary-50)', padding: notif.is_read ? '1rem 0' : '1rem', margin: notif.is_read ? '0' : '0 -1rem', paddingLeft: notif.is_read ? '0' : '1rem', paddingRight: notif.is_read ? '0' : '1rem', borderRadius: notif.is_read ? '0' : '0.5rem'}}>
                    <div className="list-item-content">
                      <p style={{color: 'var(--text-primary)', fontSize: '0.875rem', marginBottom: '0.25rem'}}>{notif.message}</p>
                      <p style={{fontSize: '0.75rem', color: 'var(--text-tertiary)'}}>
                        {new Date(notif.createdAt).toLocaleString()}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="empty-state" style={{padding: '3rem 1rem'}}>
                <Bell size={40} style={{color: 'var(--text-tertiary)'}} />
                <p style={{marginTop: '1rem', fontSize: '0.875rem', color: 'var(--text-secondary)'}}>No new notifications</p>
              </div>
            )}
          </Card>
          
          <Card style={{marginTop: '1.5rem', padding: '1.5rem'}}>
            <div className="section-header" style={{marginBottom: '1rem'}}>
              <h2 style={{fontSize: '1.125rem', fontWeight: '600', margin: 0, color: 'var(--text-primary)'}}>Quick Actions</h2>
            </div>
            <div style={{display: 'flex', flexDirection: 'column', gap: '0.75rem'}}>
              <button
                onClick={() => navigate('/citizen/report-issue')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '0.875rem 1rem',
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-color)',
                  borderRadius: 'var(--border-radius-md)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  fontSize: '0.875rem',
                  fontWeight: '500',
                  color: 'var(--text-primary)',
                  textAlign: 'left'
                }}
                onMouseEnter={(e) => {
                  e.target.style.backgroundColor = 'var(--primary-50)';
                  e.target.style.borderColor = 'var(--primary-200)';
                }}
                onMouseLeave={(e) => {
                  e.target.style.backgroundColor = 'var(--bg-surface)';
                  e.target.style.borderColor = 'var(--border-color)';
                }}
              >
                <span>Report Civic Issue</span>
                <span style={{color: 'var(--text-tertiary)', fontSize: '1.125rem'}}>→</span>
              </button>
              <button
                onClick={() => navigate('/citizen/services')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '0.875rem 1rem',
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-color)',
                  borderRadius: 'var(--border-radius-md)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  fontSize: '0.875rem',
                  fontWeight: '500',
                  color: 'var(--text-primary)',
                  textAlign: 'left'
                }}
                onMouseEnter={(e) => {
                  e.target.style.backgroundColor = 'var(--primary-50)';
                  e.target.style.borderColor = 'var(--primary-200)';
                }}
                onMouseLeave={(e) => {
                  e.target.style.backgroundColor = 'var(--bg-surface)';
                  e.target.style.borderColor = 'var(--border-color)';
                }}
              >
                <span>Browse Municipal Services</span>
                <span style={{color: 'var(--text-tertiary)', fontSize: '1.125rem'}}>→</span>
              </button>
              <button
                onClick={() => navigate('/citizen/notices')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '0.875rem 1rem',
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-color)',
                  borderRadius: 'var(--border-radius-md)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  fontSize: '0.875rem',
                  fontWeight: '500',
                  color: 'var(--text-primary)',
                  textAlign: 'left'
                }}
                onMouseEnter={(e) => {
                  e.target.style.backgroundColor = 'var(--primary-50)';
                  e.target.style.borderColor = 'var(--primary-200)';
                }}
                onMouseLeave={(e) => {
                  e.target.style.backgroundColor = 'var(--bg-surface)';
                  e.target.style.borderColor = 'var(--border-color)';
                }}
              >
                <span>View Public Notices</span>
                <span style={{color: 'var(--text-tertiary)', fontSize: '1.125rem'}}>→</span>
              </button>
              <button
                onClick={() => navigate('/citizen/my-issues')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '0.875rem 1rem',
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-color)',
                  borderRadius: 'var(--border-radius-md)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  fontSize: '0.875rem',
                  fontWeight: '500',
                  color: 'var(--text-primary)',
                  textAlign: 'left'
                }}
                onMouseEnter={(e) => {
                  e.target.style.backgroundColor = 'var(--primary-50)';
                  e.target.style.borderColor = 'var(--primary-200)';
                }}
                onMouseLeave={(e) => {
                  e.target.style.backgroundColor = 'var(--bg-surface)';
                  e.target.style.borderColor = 'var(--border-color)';
                }}
              >
                <span>View My Issues</span>
                <span style={{color: 'var(--text-tertiary)', fontSize: '1.125rem'}}>→</span>
              </button>
              <button
                onClick={() => navigate('/citizen/my-requests')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '0.875rem 1rem',
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-color)',
                  borderRadius: 'var(--border-radius-md)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  fontSize: '0.875rem',
                  fontWeight: '500',
                  color: 'var(--text-primary)',
                  textAlign: 'left'
                }}
                onMouseEnter={(e) => {
                  e.target.style.backgroundColor = 'var(--primary-50)';
                  e.target.style.borderColor = 'var(--primary-200)';
                }}
                onMouseLeave={(e) => {
                  e.target.style.backgroundColor = 'var(--bg-surface)';
                  e.target.style.borderColor = 'var(--border-color)';
                }}
              >
                <span>View My Requests</span>
                <span style={{color: 'var(--text-tertiary)', fontSize: '1.125rem'}}>→</span>
              </button>
            </div>
          </Card>
        </div>
      </div>
    </DashboardLayout>
  );
};
