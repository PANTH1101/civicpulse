import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { MapPin, Calendar, AlertCircle, RefreshCw, Filter } from 'lucide-react';
import { ModeratorDashboardLayout } from '../layouts/ModeratorDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const ModeratorIssues = () => {
  const navigate = useNavigate();
  const [issues, setIssues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('REPORTED'); // Default to pending

  const fetchIssues = async () => {
    setLoading(true);
    setError('');
    try {
      let res;
      if (filter === 'REPORTED') {
        res = await api.get('/issues/moderator/pending');
      } else {
        res = await api.get('/issues/moderator');
      }
      
      let filteredIssues = res.issues || [];
      
      // Apply additional filter if not showing pending
      if (filter !== 'REPORTED' && filter !== 'ALL') {
        filteredIssues = filteredIssues.filter(issue => issue.status === filter);
      }
      
      setIssues(filteredIssues);
    } catch (err) {
      setError('Unable to load civic issues.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchIssues();
  }, [filter]);

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
    <ModeratorDashboardLayout>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem'}}>
        <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
          Civic Issues
        </h1>
      </div>

      {/* Filter */}
      <Card style={{marginBottom: '1.5rem', padding: '1rem'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem', flexWrap: 'wrap'}}>
          <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem', fontWeight: '500'}}>
            <Filter size={16} />
            Filter:
          </div>
          <select 
            value={filter} 
            onChange={(e) => setFilter(e.target.value)}
            className="input-field"
            style={{width: 'auto', minWidth: '200px', padding: '0.5rem 0.75rem'}}
          >
            <option value="REPORTED">Pending Review</option>
            <option value="ALL">All Issues</option>
            <option value="ASSIGNED">Assigned</option>
            <option value="IN_PROGRESS">In Progress</option>
            <option value="RESOLVED">Resolved</option>
            <option value="REJECTED">Rejected</option>
          </select>
        </div>
      </Card>

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
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem'}}>
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
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>No issues found</h3>
              <p style={{margin: 0, maxWidth: '400px'}}>
                {filter === 'REPORTED' ? 'No pending issues require review at this time.' : `No issues found with status: ${filter}`}
              </p>
            </div>
          </div>
        </Card>
      ) : (
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem'}}>
          {issues.map(issue => (
            <Card 
              key={issue.id || issue._id} 
              style={{
                padding: '1.5rem', 
                display: 'flex', 
                flexDirection: 'column',
                cursor: 'pointer',
                transition: 'transform 0.2s, box-shadow 0.2s'
              }}
              onClick={() => navigate(`/moderator/issues/${issue.id || issue._id}`)}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-2px)';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '';
              }}
            >
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem'}}>
                <h3 style={{margin: 0, fontSize: '1.125rem', fontWeight: '600', color: 'var(--text-primary)', flex: 1}}>
                  {issue.title}
                </h3>
                {getStatusBadge(issue.status)}
              </div>
              
              <div style={{fontSize: '0.875rem', color: 'var(--text-secondary)', marginBottom: '0.5rem'}}>
                <strong>Category:</strong> {issue.category}
              </div>
              
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', color: 'var(--text-secondary)', marginBottom: '0.5rem'}}>
                <MapPin size={14} />
                {issue.location}
              </div>
              
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', color: 'var(--text-tertiary)'}}>
                <Calendar size={14} />
                {new Date(issue.createdAt).toLocaleDateString()}
              </div>
              
              {issue.reportedBy && (
                <div style={{marginTop: '0.75rem', paddingTop: '0.75rem', borderTop: '1px solid var(--border-color)', fontSize: '0.875rem', color: 'var(--text-secondary)'}}>
                  Reported by: {issue.reportedBy.name || 'Unknown'}
                </div>
              )}
              
              <div style={{marginTop: 'auto', paddingTop: '1rem'}}>
                <Button 
                  variant="primary" 
                  style={{width: '100%', fontSize: '0.875rem'}}
                  onClick={(e) => {
                    e.stopPropagation();
                    navigate(`/moderator/issues/${issue.id || issue._id}`);
                  }}
                >
                  {issue.status === 'REPORTED' ? 'Review Issue' : 'View Details'}
                </Button>
              </div>
            </Card>
          ))}
        </div>
      )}
    </ModeratorDashboardLayout>
  );
};
