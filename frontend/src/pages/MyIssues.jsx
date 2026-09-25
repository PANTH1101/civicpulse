import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, MapPin, Calendar, ArrowRight, AlertCircle, RefreshCw } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const MyIssues = () => {
  const navigate = useNavigate();
  const [issues, setIssues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchIssues = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/issues/my-issues');
      setIssues(res.issues || []);
    } catch (err) {
      setError('Unable to load your civic issues.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchIssues();
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

  return (
    <DashboardLayout>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem'}}>
        <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
          My Civic Issues
        </h1>
        <Button variant="primary" onClick={() => navigate('/citizen/report-issue')} style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
          <Plus size={18} />
          Report an Issue
        </Button>
      </div>

      {error ? (
        <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Issues</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error}</p>
            </div>
            <Button variant="outline" onClick={fetchIssues} style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '1rem'}}>
              <RefreshCw size={16} />
              Retry
            </Button>
          </div>
        </Card>
      ) : loading ? (
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.5rem'}}>
          {[1, 2, 3].map(i => (
            <Card key={i} style={{padding: '1.5rem'}}>
              <div style={{height: '24px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '70%', marginBottom: '1rem'}} />
              <div style={{height: '16px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '40%', marginBottom: '0.5rem'}} />
              <div style={{height: '16px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '50%', marginBottom: '1.5rem'}} />
              <div style={{height: '32px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '100%'}} />
            </Card>
          ))}
        </div>
      ) : issues.length === 0 ? (
        <Card style={{textAlign: 'center', padding: '4rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--text-secondary)'}}>
            <div style={{width: '64px', height: '64px', borderRadius: '50%', backgroundColor: 'var(--primary-50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-600)'}}>
              <AlertCircle size={32} />
            </div>
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>No civic issues reported yet.</h3>
              <p style={{margin: 0, maxWidth: '400px'}}>When you report civic issues like potholes or broken streetlights, they will appear here.</p>
            </div>
            <Button variant="primary" onClick={() => navigate('/citizen/report-issue')} style={{marginTop: '1rem'}}>
              Report an Issue
            </Button>
          </div>
        </Card>
      ) : (
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem'}}>
          {issues.map(issue => (
            <Card key={issue.id || issue._id} style={{padding: '1.5rem', display: 'flex', flexDirection: 'column'}}>
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem'}}>
                <h3 style={{margin: 0, fontSize: '1.125rem', fontWeight: '600', color: 'var(--text-primary)'}}>
                  {issue.title}
                </h3>
                {getStatusBadge(issue.status)}
              </div>
              
              <div style={{display: 'flex', flexDirection: 'column', gap: '0.5rem', marginBottom: '1.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <span style={{fontWeight: '500', color: 'var(--text-primary)'}}>{issue.category}</span>
                </div>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <MapPin size={16} />
                  {issue.location}
                </div>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <Calendar size={16} />
                  {new Date(issue.createdAt).toLocaleDateString()}
                </div>
              </div>
              
              <div style={{marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid var(--border-color)'}}>
                <Button 
                  variant="outline" 
                  style={{width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem'}}
                  onClick={() => navigate(`/citizen/issues/${issue.id || issue._id}`)}
                >
                  View Details
                  <ArrowRight size={16} />
                </Button>
              </div>
            </Card>
          ))}
        </div>
      )}
    </DashboardLayout>
  );
};
