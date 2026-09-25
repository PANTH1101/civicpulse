import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Megaphone, Calendar, ArrowRight, AlertCircle, RefreshCw } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const PublicNotices = () => {
  const navigate = useNavigate();
  const [notices, setNotices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchNotices = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/notices');
      setNotices(res.notices || []);
    } catch (err) {
      setError('Unable to load public notices.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotices();
  }, []);

  const getCategoryBadge = (category) => {
    switch(category) {
      case 'EMERGENCY': 
        return <span style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>EMERGENCY</span>;
      case 'MAINTENANCE': 
        return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>MAINTENANCE</span>;
      case 'EVENT': 
        return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>EVENT</span>;
      case 'POLICY': 
        return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>POLICY</span>;
      case 'ANNOUNCEMENT': 
        return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>ANNOUNCEMENT</span>;
      case 'GENERAL':
        return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>GENERAL</span>;
      default: 
        return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>{category}</span>;
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
  };

  return (
    <DashboardLayout>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem'}}>
        <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
          Public Notices
        </h1>
      </div>

      {error ? (
        <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Notices</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error}</p>
            </div>
            <Button variant="outline" onClick={fetchNotices} style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '1rem'}}>
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
              <div style={{height: '60px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '100%', marginBottom: '1rem'}} />
              <div style={{height: '32px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '100%'}} />
            </Card>
          ))}
        </div>
      ) : notices.length === 0 ? (
        <Card style={{textAlign: 'center', padding: '4rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--text-secondary)'}}>
            <div style={{width: '64px', height: '64px', borderRadius: '50%', backgroundColor: 'var(--primary-50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-600)'}}>
              <Megaphone size={32} />
            </div>
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>No public notices available</h3>
              <p style={{margin: 0, maxWidth: '400px'}}>There are currently no published public notices. Check back later for important announcements and updates.</p>
            </div>
          </div>
        </Card>
      ) : (
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem'}}>
          {notices.map(notice => (
            <Card 
              key={notice.id} 
              style={{
                padding: '1.5rem', 
                display: 'flex', 
                flexDirection: 'column',
                cursor: 'pointer',
                transition: 'transform 0.2s, box-shadow 0.2s',
              }}
              onClick={() => navigate(`/citizen/notices/${notice.id}`)}
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
                <div style={{flex: 1}}>
                  {getCategoryBadge(notice.category)}
                </div>
              </div>
              
              <h3 style={{margin: '0 0 0.75rem 0', fontSize: '1.125rem', fontWeight: '600', color: 'var(--text-primary)', lineHeight: '1.4'}}>
                {notice.title}
              </h3>
              
              <p style={{
                color: 'var(--text-secondary)', 
                fontSize: '0.875rem', 
                marginBottom: '1rem', 
                lineHeight: '1.6',
                display: '-webkit-box',
                WebkitLineClamp: 3,
                WebkitBoxOrient: 'vertical',
                overflow: 'hidden',
                flexGrow: 1
              }}>
                {notice.content}
              </p>
              
              <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid var(--border-color)'}}>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-tertiary)', fontSize: '0.75rem'}}>
                  <Calendar size={14} />
                  {formatDate(notice.publishedAt)}
                </div>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.25rem', color: 'var(--primary-600)', fontSize: '0.875rem', fontWeight: '500'}}>
                  Read More
                  <ArrowRight size={16} />
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </DashboardLayout>
  );
};
