import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { AlertCircle, CheckCircle, Clock, ListChecks, ArrowRight, RefreshCw, Package, Hourglass, PlayCircle } from 'lucide-react';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const DepartmentDashboard = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    assigned: 0,
    inProgress: 0,
    resolved: 0
  });
  const [serviceStats, setServiceStats] = useState({
    pending: 0,
    accepted: 0,
    inProgress: 0,
    completed: 0
  });
  const [recentIssues, setRecentIssues] = useState([]);
  const [recentServiceRequests, setRecentServiceRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError('');
    
    try {
      // Fetch civic issue stats
      const [assignedRes, inProgressRes, resolvedRes, recentRes] = await Promise.all([
        api.get('/departments/my-issues?status=ASSIGNED&limit=1'),
        api.get('/departments/my-issues?status=IN_PROGRESS&limit=1'),
        api.get('/departments/my-issues?status=RESOLVED&limit=1'),
        api.get('/departments/my-issues?limit=5')
      ]);

      setStats({
        assigned: assignedRes.total || 0,
        inProgress: inProgressRes.total || 0,
        resolved: resolvedRes.total || 0
      });

      setRecentIssues(recentRes.issues || []);

      // Fetch service request stats
      const [pendingReqRes, acceptedReqRes, inProgressReqRes, completedReqRes, recentReqRes] = await Promise.all([
        api.get('/departments/service-requests?status=PENDING&limit=1'),
        api.get('/departments/service-requests?status=ACCEPTED&limit=1'),
        api.get('/departments/service-requests?status=IN_PROGRESS&limit=1'),
        api.get('/departments/service-requests?status=COMPLETED&limit=1'),
        api.get('/departments/service-requests?limit=5')
      ]);

      setServiceStats({
        pending: pendingReqRes.total || 0,
        accepted: acceptedReqRes.total || 0,
        inProgress: inProgressReqRes.total || 0,
        completed: completedReqRes.total || 0
      });

      setRecentServiceRequests(recentReqRes.requests || []);
    } catch (err) {
      setError('Unable to load dashboard data.');
    } finally {
      setLoading(false);
    }
  };

  const getIssueStatusBadge = (status) => {
    switch(status) {
      case 'ASSIGNED': return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>ASSIGNED</span>;
      case 'IN_PROGRESS': return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>IN PROGRESS</span>;
      case 'RESOLVED': return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>RESOLVED</span>;
      default: return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>{status}</span>;
    }
  };

  const getServiceRequestStatusBadge = (status) => {
    switch(status) {
      case 'PENDING': return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>PENDING</span>;
      case 'ACCEPTED': return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>ACCEPTED</span>;
      case 'IN_PROGRESS': return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>IN PROGRESS</span>;
      case 'COMPLETED': return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>COMPLETED</span>;
      default: return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>{status}</span>;
    }
  };

  if (loading) {
    return (
      <DepartmentDashboardLayout>
        <div style={{display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px'}}>
          <div style={{textAlign: 'center', color: 'var(--text-secondary)'}}>
            <RefreshCw size={32} className="animate-spin" style={{margin: '0 auto 1rem'}} />
            <p>Loading dashboard...</p>
          </div>
        </div>
      </DepartmentDashboardLayout>
    );
  }

  return (
    <DepartmentDashboardLayout>
      {/* Page Header - Compact */}
      <div style={{marginBottom: '2rem'}}>
        <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: '0 0 0.25rem 0'}}>
          Department Dashboard
        </h1>
        <p style={{margin: 0, color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
          Manage civic issues and service requests assigned to your department
        </p>
      </div>

      {error && (
        <Card style={{marginBottom: '1.5rem', padding: '1rem', backgroundColor: 'var(--danger-50)', borderColor: 'var(--danger-200)'}}>
          <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--danger-700)'}}>
            <AlertCircle size={20} />
            <span>{error}</span>
          </div>
        </Card>
      )}

      {/* Civic Issues Stats - Compact matching Citizen */}
      <div style={{marginBottom: '2rem'}}>
        <h2 style={{fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)', margin: '0 0 0.75rem 0'}}>
          Civic Issues
        </h2>
        <div className="dashboard-grid">
          <Card className="stat-card" style={{padding: '1.25rem', cursor: 'pointer'}} onClick={() => navigate('/department/issues?status=ASSIGNED')}>
            <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', backgroundColor: 'var(--info-50)', color: 'var(--info-600)', flexShrink: 0}}>
              <ListChecks size={22} />
            </div>
            <div className="stat-info">
              <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{stats.assigned}</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Assigned</p>
            </div>
          </Card>

          <Card className="stat-card" style={{padding: '1.25rem', cursor: 'pointer'}} onClick={() => navigate('/department/issues?status=IN_PROGRESS')}>
            <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', backgroundColor: 'var(--primary-50)', color: 'var(--primary-600)', flexShrink: 0}}>
              <Clock size={22} />
            </div>
            <div className="stat-info">
              <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{stats.inProgress}</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>In Progress</p>
            </div>
          </Card>

          <Card className="stat-card" style={{padding: '1.25rem', cursor: 'pointer'}} onClick={() => navigate('/department/issues?status=RESOLVED')}>
            <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', backgroundColor: 'var(--success-50)', color: 'var(--success-600)', flexShrink: 0}}>
              <CheckCircle size={22} />
            </div>
            <div className="stat-info">
              <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{stats.resolved}</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Resolved</p>
            </div>
          </Card>
        </div>
      </div>

      {/* Service Requests Stats - Compact matching Citizen */}
      <div style={{marginBottom: '2rem'}}>
        <h2 style={{fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)', margin: '0 0 0.75rem 0'}}>
          Municipal Service Requests
        </h2>
        <div className="dashboard-grid">
          <Card className="stat-card" style={{padding: '1.25rem', cursor: 'pointer'}} onClick={() => navigate('/department/service-requests?status=PENDING')}>
            <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', backgroundColor: 'var(--warning-50)', color: 'var(--warning-600)', flexShrink: 0}}>
              <Hourglass size={22} />
            </div>
            <div className="stat-info">
              <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{serviceStats.pending}</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Pending</p>
            </div>
          </Card>

          <Card className="stat-card" style={{padding: '1.25rem', cursor: 'pointer'}} onClick={() => navigate('/department/service-requests?status=ACCEPTED')}>
            <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', backgroundColor: 'var(--info-50)', color: 'var(--info-600)', flexShrink: 0}}>
              <CheckCircle size={22} />
            </div>
            <div className="stat-info">
              <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{serviceStats.accepted}</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Accepted</p>
            </div>
          </Card>

          <Card className="stat-card" style={{padding: '1.25rem', cursor: 'pointer'}} onClick={() => navigate('/department/service-requests?status=IN_PROGRESS')}>
            <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', backgroundColor: 'var(--primary-50)', color: 'var(--primary-600)', flexShrink: 0}}>
              <PlayCircle size={22} />
            </div>
            <div className="stat-info">
              <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{serviceStats.inProgress}</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>In Progress</p>
            </div>
          </Card>

          <Card className="stat-card" style={{padding: '1.25rem', cursor: 'pointer'}} onClick={() => navigate('/department/service-requests?status=COMPLETED')}>
            <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', backgroundColor: 'var(--success-50)', color: 'var(--success-600)', flexShrink: 0}}>
              <Package size={22} />
            </div>
            <div className="stat-info">
              <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{serviceStats.completed}</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Completed</p>
            </div>
          </Card>
        </div>
      </div>

      {/* Recent Sections - 2 Column Layout */}
      <div className="department-recent-grid">
        {/* Recent Civic Issues */}
        <Card style={{padding: '1.5rem'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem'}}>
            <h2 style={{margin: 0, fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)'}}>
              Recent Civic Issues
            </h2>
            <Button 
              variant="ghost" 
              onClick={() => navigate('/department/issues')}
              style={{display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem 0.75rem'}}
            >
              View All
              <ArrowRight size={16} />
            </Button>
          </div>

          {recentIssues.length === 0 ? (
            <div className="empty-state">
              <AlertCircle size={40} style={{margin: '0 auto 0.75rem', opacity: 0.3, color: 'var(--text-tertiary)'}} />
              <h3 style={{margin: '0 0 0.375rem 0', fontSize: '0.9375rem', fontWeight: '600', color: 'var(--text-primary)'}}>No issues assigned yet</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)'}}>Assigned issues will appear here.</p>
            </div>
          ) : (
            <div style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
              {recentIssues.map((issue) => (
                <div
                  key={issue.id}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '1rem',
                    backgroundColor: 'var(--bg-secondary)',
                    borderRadius: 'var(--border-radius-md)',
                    cursor: 'pointer',
                    transition: 'background-color 0.2s'
                  }}
                  onClick={() => navigate(`/department/issues/${issue.id}`)}
                  onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'var(--bg-tertiary)'}
                  onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'var(--bg-secondary)'}
                >
                  <div style={{flex: 1}}>
                    <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem'}}>
                      <h3 style={{margin: 0, fontSize: '0.9375rem', fontWeight: '500', color: 'var(--text-primary)'}}>
                        {issue.title}
                      </h3>
                      {getIssueStatusBadge(issue.status)}
                    </div>
                    <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)'}}>
                      {issue.category} • {issue.location}
                    </p>
                  </div>
                  <ArrowRight size={20} style={{color: 'var(--text-tertiary)'}} />
                </div>
              ))}
            </div>
          )}
        </Card>

        {/* Recent Service Requests */}
        <Card style={{padding: '1.5rem'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem'}}>
            <h2 style={{margin: 0, fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)'}}>
              Recent Service Requests
            </h2>
            <Button 
              variant="ghost" 
              onClick={() => navigate('/department/service-requests')}
              style={{display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem 0.75rem'}}
            >
              View All
              <ArrowRight size={16} />
            </Button>
          </div>

          {recentServiceRequests.length === 0 ? (
            <div className="empty-state">
              <Package size={40} style={{margin: '0 auto 0.75rem', opacity: 0.3, color: 'var(--text-tertiary)'}} />
              <h3 style={{margin: '0 0 0.375rem 0', fontSize: '0.9375rem', fontWeight: '600', color: 'var(--text-primary)'}}>No service requests assigned yet</h3>
              <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)'}}>Assigned requests will appear here.</p>
            </div>
          ) : (
            <div style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
              {recentServiceRequests.map((request) => (
                <div
                  key={request.id}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '1rem',
                    backgroundColor: 'var(--bg-secondary)',
                    borderRadius: 'var(--border-radius-md)',
                    cursor: 'pointer',
                    transition: 'background-color 0.2s'
                  }}
                  onClick={() => navigate(`/department/service-requests/${request.id}`)}
                  onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'var(--bg-tertiary)'}
                  onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'var(--bg-secondary)'}
                >
                  <div style={{flex: 1}}>
                    <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem'}}>
                      <h3 style={{margin: 0, fontSize: '0.9375rem', fontWeight: '500', color: 'var(--text-primary)'}}>
                        {request.service?.name || 'Unknown Service'}
                      </h3>
                      {getServiceRequestStatusBadge(request.status)}
                    </div>
                    <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)'}}>
                      {request.service?.category || 'N/A'} • Submitted {new Date(request.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                  <ArrowRight size={20} style={{color: 'var(--text-tertiary)'}} />
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </DepartmentDashboardLayout>
  );
};
