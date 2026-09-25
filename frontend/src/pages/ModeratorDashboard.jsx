import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ModeratorDashboardLayout } from '../layouts/ModeratorDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { AlertCircle, Clock, CheckCircle2, XCircle, ArrowRight, AlertTriangle } from 'lucide-react';
import { api } from '../services/api';

export const ModeratorDashboard = () => {
  const navigate = useNavigate();
  
  const [pendingIssues, setPendingIssues] = useState([]);
  const [allIssues, setAllIssues] = useState([]);
  const [loadingPending, setLoadingPending] = useState(true);
  const [loadingAll, setLoadingAll] = useState(true);
  const [error, setError] = useState('');

  const fetchPendingIssues = async () => {
    setLoadingPending(true);
    setError('');
    try {
      const res = await api.get('/issues/moderator/pending');
      setPendingIssues(res.issues || []);
    } catch (error) {
      setError('Unable to load pending issues.');
    } finally {
      setLoadingPending(false);
    }
  };

  const fetchAllIssues = async () => {
    setLoadingAll(true);
    try {
      const res = await api.get('/issues/moderator');
      setAllIssues(res.issues || []);
    } catch (error) {
      // Silent fail for stats
    } finally {
      setLoadingAll(false);
    }
  };

  useEffect(() => {
    fetchPendingIssues();
    fetchAllIssues();
  }, []);

  const getStatusBadge = (status) => {
    switch(status) {
      case 'REPORTED': return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>REPORTED</span>;
      case 'ASSIGNED': return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>ASSIGNED</span>;
      case 'IN_PROGRESS': return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>IN PROGRESS</span>;
      case 'RESOLVED': return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>RESOLVED</span>;
      case 'REJECTED': return <span style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>REJECTED</span>;
      default: return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>{status}</span>;
    }
  };

  const assignedCount = allIssues.filter(i => i.status === 'ASSIGNED').length;
  const inProgressCount = allIssues.filter(i => i.status === 'IN_PROGRESS').length;
  const resolvedCount = allIssues.filter(i => i.status === 'RESOLVED').length;
  const rejectedCount = allIssues.filter(i => i.status === 'REJECTED').length;

  return (
    <ModeratorDashboardLayout>
      {/* Summary Cards - Matching Citizen */}
      <div className="dashboard-grid" style={{marginBottom: '2rem'}}>
        <Card className="stat-card" style={{padding: '1.25rem'}}>
          <div className="stat-icon warning" style={{width: '2.75rem', height: '2.75rem', flexShrink: 0}}>
            <Clock size={22} />
          </div>
          <div className="stat-info">
            <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{loadingPending ? '...' : pendingIssues.length}</h3>
            <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Pending Review</p>
          </div>
        </Card>
        
        <Card className="stat-card" style={{padding: '1.25rem'}}>
          <div className="stat-icon" style={{width: '2.75rem', height: '2.75rem', backgroundColor: 'var(--info-50)', color: 'var(--info-600)', flexShrink: 0}}>
            <AlertCircle size={22} />
          </div>
          <div className="stat-info">
            <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{loadingAll ? '...' : assignedCount}</h3>
            <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Assigned</p>
          </div>
        </Card>
        
        <Card className="stat-card" style={{padding: '1.25rem'}}>
          <div className="stat-icon primary" style={{width: '2.75rem', height: '2.75rem', flexShrink: 0}}>
            <Clock size={22} />
          </div>
          <div className="stat-info">
            <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{loadingAll ? '...' : inProgressCount}</h3>
            <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>In Progress</p>
          </div>
        </Card>
        
        <Card className="stat-card" style={{padding: '1.25rem'}}>
          <div className="stat-icon success" style={{width: '2.75rem', height: '2.75rem', flexShrink: 0}}>
            <CheckCircle2 size={22} />
          </div>
          <div className="stat-info">
            <h3 style={{fontSize: '1.75rem', fontWeight: '700', marginBottom: '0.25rem', color: 'var(--text-primary)'}}>{loadingAll ? '...' : resolvedCount}</h3>
            <p style={{margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)', fontWeight: '500'}}>Resolved</p>
          </div>
        </Card>
      </div>

      <div className="dashboard-sections">
        {/* Main Content Area */}
        <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
          
          {/* Pending Issues */}
          <Card>
            <div className="section-header">
              <h2>Pending Civic Issues</h2>
              <Button variant="outline" style={{padding: '0.5rem 1rem'}} onClick={() => navigate('/moderator/issues')}>
                View All
              </Button>
            </div>
            
            {loadingPending ? (
              <div style={{padding: '2rem', textAlign: 'center', color: 'var(--text-secondary)'}}>
                Loading pending issues...
              </div>
            ) : error ? (
              <div style={{padding: '2rem', textAlign: 'center', color: 'var(--danger-600)'}}>
                <AlertTriangle size={32} style={{margin: '0 auto 1rem'}} />
                <p>{error}</p>
                <Button variant="outline" onClick={fetchPendingIssues} style={{marginTop: '1rem'}}>Retry</Button>
              </div>
            ) : pendingIssues.length > 0 ? (
              <div style={{display: 'flex', flexDirection: 'column'}}>
                {pendingIssues.slice(0, 5).map(issue => (
                  <div key={issue.id} className="list-item">
                    <div className="list-item-content">
                      <h4>{issue.title}</h4>
                      <p>{issue.category} • {issue.location} • {new Date(issue.createdAt).toLocaleDateString()}</p>
                    </div>
                    <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
                      {getStatusBadge(issue.status)}
                      <Button variant="primary" style={{padding: '0.25rem 0.75rem', fontSize: '0.75rem'}} onClick={() => navigate(`/moderator/issues/${issue.id}`)}>
                        Review
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="empty-state">
                <CheckCircle2 size={48} />
                <h3>No pending issues</h3>
                <p style={{margin: '0.5rem 0 1.5rem'}}>All reported issues have been reviewed.</p>
              </div>
            )}
          </Card>
        </div>

        {/* Sidebar Area */}
        <div>
          <Card>
            <div className="section-header">
              <h2>Quick Stats</h2>
            </div>
            
            <div style={{display: 'flex', flexDirection: 'column', gap: '1rem', padding: '0.5rem 0'}}>
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <div style={{width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--warning-500)'}} />
                  <span style={{fontSize: '0.875rem', color: 'var(--text-secondary)'}}>Pending Review</span>
                </div>
                <span style={{fontWeight: '600', color: 'var(--text-primary)'}}>{pendingIssues.length}</span>
              </div>
              
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <div style={{width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--info-500)'}} />
                  <span style={{fontSize: '0.875rem', color: 'var(--text-secondary)'}}>Assigned</span>
                </div>
                <span style={{fontWeight: '600', color: 'var(--text-primary)'}}>{assignedCount}</span>
              </div>
              
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <div style={{width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--primary-500)'}} />
                  <span style={{fontSize: '0.875rem', color: 'var(--text-secondary)'}}>In Progress</span>
                </div>
                <span style={{fontWeight: '600', color: 'var(--text-primary)'}}>{inProgressCount}</span>
              </div>
              
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <div style={{width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--success-500)'}} />
                  <span style={{fontSize: '0.875rem', color: 'var(--text-secondary)'}}>Resolved</span>
                </div>
                <span style={{fontWeight: '600', color: 'var(--text-primary)'}}>{resolvedCount}</span>
              </div>
              
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <div style={{width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--danger-500)'}} />
                  <span style={{fontSize: '0.875rem', color: 'var(--text-secondary)'}}>Rejected</span>
                </div>
                <span style={{fontWeight: '600', color: 'var(--text-primary)'}}>{rejectedCount}</span>
              </div>
            </div>
          </Card>
          
          <Card style={{marginTop: '1.5rem'}}>
            <div className="section-header">
              <h2>Quick Actions</h2>
            </div>
            <div style={{display: 'flex', flexDirection: 'column', gap: '0.5rem'}}>
              <Button variant="secondary" style={{justifyContent: 'flex-start', padding: '0.75rem'}} onClick={() => navigate('/moderator/issues')}>View All Issues</Button>
            </div>
          </Card>
        </div>
      </div>
    </ModeratorDashboardLayout>
  );
};
