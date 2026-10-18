import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Megaphone, Plus, Calendar, Eye, Send, AlertCircle, RefreshCw } from 'lucide-react';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const DepartmentNotices = () => {
  const navigate = useNavigate();
  const [notices, setNotices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [publishing, setPublishing] = useState(null);

  const fetchNotices = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/notices/all');
      setNotices(res.notices || []);
    } catch (err) {
      setError('Unable to load notices.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotices();
  }, []);

  const handlePublish = async (noticeId) => {
    if (!window.confirm('Are you sure you want to publish this notice? All citizens will be notified.')) {
      return;
    }

    setPublishing(noticeId);
    try {
      await api.patch(`/notices/${noticeId}/publish`);
      await fetchNotices();
    } catch (err) {
      alert(err.message || 'Failed to publish notice');
    } finally {
      setPublishing(null);
    }
  };

  const getStatusBadge = (status) => {
    if (status === 'DRAFT') {
      return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>DRAFT</span>;
    }
    return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>PUBLISHED</span>;
  };

  const getCategoryBadge = (category) => {
    const colors = {
      'EMERGENCY': { bg: 'var(--danger-100)', text: 'var(--danger-700)' },
      'MAINTENANCE': { bg: 'var(--warning-100)', text: 'var(--warning-700)' },
      'EVENT': { bg: 'var(--info-100)', text: 'var(--info-700)' },
      'POLICY': { bg: 'var(--primary-100)', text: 'var(--primary-700)' },
      'ANNOUNCEMENT': { bg: 'var(--success-100)', text: 'var(--success-700)' },
      'GENERAL': { bg: 'var(--bg-secondary)', text: 'var(--text-secondary)' },
    };
    const color = colors[category] || colors['GENERAL'];
    return <span style={{backgroundColor: color.bg, color: color.text, padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>{category}</span>;
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric'
    });
  };

  return (
    <DepartmentDashboardLayout>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem'}}>
        <div>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: '0 0 0.25rem 0'}}>
            Public Notices
          </h1>
          <p style={{margin: 0, color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
            Manage your department's public notices
          </p>
        </div>
        <Button 
          variant="primary" 
          onClick={() => navigate('/department/create-notice')}
          style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}
        >
          <Plus size={16} />
          Create Notice
        </Button>
      </div>

      {error && (
        <Card style={{marginBottom: '1.5rem', padding: '1rem', backgroundColor: 'var(--danger-50)', borderColor: 'var(--danger-200)'}}>
          <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--danger-700)'}}>
            <AlertCircle size={20} />
            <span>{error}</span>
          </div>
        </Card>
      )}

      {loading ? (
        <Card style={{padding: '2rem', textAlign: 'center'}}>
          <RefreshCw size={32} className="animate-spin" style={{margin: '0 auto 1rem', color: 'var(--primary-600)'}} />
          <p style={{color: 'var(--text-secondary)'}}>Loading notices...</p>
        </Card>
      ) : notices.length === 0 ? (
        <Card style={{padding: '3rem', textAlign: 'center'}}>
          <Megaphone size={48} style={{margin: '0 auto 1rem', color: 'var(--text-tertiary)'}} />
          <h3 style={{margin: '0 0 0.5rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)'}}>
            No notices yet
          </h3>
          <p style={{margin: '0 0 1.5rem 0', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
            Create your first public notice to inform citizens
          </p>
          <Button variant="primary" onClick={() => navigate('/department/create-notice')}>
            <Plus size={16} style={{marginRight: '0.5rem'}} />
            Create Notice
          </Button>
        </Card>
      ) : (
        <div style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
          {notices.map((notice) => (
            <Card key={notice.id} style={{padding: '1.25rem'}}>
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '1rem'}}>
                <div style={{flex: 1, minWidth: 0}}>
                  <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem', flexWrap: 'wrap'}}>
                    {getStatusBadge(notice.status)}
                    {getCategoryBadge(notice.category)}
                  </div>
                  
                  <h3 style={{margin: '0 0 0.5rem 0', fontSize: '1.125rem', fontWeight: '600', color: 'var(--text-primary)'}}>
                    {notice.title}
                  </h3>
                  
                  <p style={{
                    margin: '0 0 0.75rem 0',
                    color: 'var(--text-secondary)',
                    fontSize: '0.875rem',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                    overflow: 'hidden'
                  }}>
                    {notice.content}
                  </p>
                  
                  <div style={{display: 'flex', alignItems: 'center', gap: '1rem', fontSize: '0.75rem', color: 'var(--text-tertiary)'}}>
                    <span style={{display: 'flex', alignItems: 'center', gap: '0.25rem'}}>
                      <Calendar size={14} />
                      Created: {formatDate(notice.createdAt)}
                    </span>
                    {notice.status === 'PUBLISHED' && (
                      <span style={{display: 'flex', alignItems: 'center', gap: '0.25rem'}}>
                        <Calendar size={14} />
                        Published: {formatDate(notice.publishedAt)}
                      </span>
                    )}
                  </div>
                </div>

                <div style={{display: 'flex', gap: '0.5rem', flexShrink: 0}}>
                  <Button 
                    variant="outline"
                    onClick={() => navigate(`/department/notices/${notice.id}`)}
                    style={{display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem 0.75rem'}}
                  >
                    <Eye size={16} />
                    View
                  </Button>
                  
                  {notice.status === 'DRAFT' && (
                    <Button 
                      variant="primary"
                      onClick={() => handlePublish(notice.id)}
                      disabled={publishing === notice.id}
                      style={{display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem 0.75rem'}}
                    >
                      {publishing === notice.id ? (
                        <>
                          <RefreshCw size={16} className="animate-spin" />
                          Publishing...
                        </>
                      ) : (
                        <>
                          <Send size={16} />
                          Publish
                        </>
                      )}
                    </Button>
                  )}
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </DepartmentDashboardLayout>
  );
};
