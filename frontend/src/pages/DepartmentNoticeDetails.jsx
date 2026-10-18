import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Calendar, Building2, AlertCircle, RefreshCw, Send } from 'lucide-react';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const DepartmentNoticeDetails = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const [notice, setNotice] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [publishing, setPublishing] = useState(false);

  const fetchNotice = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get(`/notices/${id}`);
      setNotice(res.notice);
    } catch (err) {
      setError(err.message || 'Unable to load notice details.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotice();
  }, [id]);

  const handlePublish = async () => {
    if (!window.confirm('Are you sure you want to publish this notice? All citizens will be notified.')) {
      return;
    }

    setPublishing(true);
    try {
      await api.patch(`/notices/${id}/publish`);
      await fetchNotice();
      alert('Notice published successfully!');
    } catch (err) {
      alert(err.message || 'Failed to publish notice');
    } finally {
      setPublishing(false);
    }
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
    return <span style={{backgroundColor: color.bg, color: color.text, padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>{category}</span>;
  };

  const getStatusBadge = (status) => {
    if (status === 'DRAFT') {
      return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>DRAFT</span>;
    }
    return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>PUBLISHED</span>;
  };

  const formatDateTime = (dateString) => {
    if (!dateString) return null;
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const formatDateOnly = (dateString) => {
    if (!dateString) return null;
    // Extract just the date part to avoid timezone conversion issues
    const datePart = dateString.split('T')[0];
    const [year, month, day] = datePart.split('-');
    const date = new Date(year, month - 1, day);
    return date.toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric'
    });
  };

  return (
    <DepartmentDashboardLayout>
      <div style={{maxWidth: '900px', margin: '0 auto'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem'}}>
          <button 
            onClick={() => navigate('/department/notices')}
            style={{background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', color: 'var(--text-secondary)'}}
          >
            <ArrowLeft size={20} />
          </button>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
            Notice Details
          </h1>
        </div>

        {error ? (
          <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
              <AlertCircle size={40} />
              <div>
                <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Notice</h3>
                <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error}</p>
              </div>
              <Button variant="outline" onClick={fetchNotice} style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '1rem'}}>
                <RefreshCw size={16} />
                Retry
              </Button>
            </div>
          </Card>
        ) : loading ? (
          <Card style={{padding: '2rem', textAlign: 'center'}}>
            <RefreshCw size={32} className="animate-spin" style={{margin: '0 auto 1rem', color: 'var(--primary-600)'}} />
            <p style={{color: 'var(--text-secondary)'}}>Loading notice...</p>
          </Card>
        ) : !notice ? (
          <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
            <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Notice not found</h3>
            <Button variant="primary" onClick={() => navigate('/department/notices')}>
              Back to Notices
            </Button>
          </Card>
        ) : (
          <Card style={{padding: '2rem'}}>
            {/* Badges */}
            <div style={{display: 'flex', gap: '0.75rem', marginBottom: '1.5rem'}}>
              {getStatusBadge(notice.status)}
              {getCategoryBadge(notice.category)}
            </div>

            {/* Title */}
            <h2 style={{fontSize: '2.5rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '1.5rem', lineHeight: '1.3'}}>
              {notice.title}
            </h2>

            {/* Meta Information */}
            <div style={{display: 'flex', flexDirection: 'column', gap: '0.75rem', marginBottom: '2rem', paddingBottom: '1.5rem', borderBottom: '1px solid var(--border-color)'}}>
              {notice.department && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <Building2 size={16} />
                  <span><strong>Department:</strong> {notice.department.name}</span>
                </div>
              )}
              
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                <Calendar size={16} />
                <span>Created: {formatDateTime(notice.createdAt)}</span>
              </div>

              {notice.publishedAt && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <Calendar size={16} />
                  <span>Published: {formatDateTime(notice.publishedAt)}</span>
                </div>
              )}

              {notice.startDate && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <Calendar size={16} />
                  <span>Start Date: {formatDateOnly(notice.startDate)}</span>
                </div>
              )}

              {notice.endDate && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <Calendar size={16} />
                  <span>End Date: {formatDateOnly(notice.endDate)}</span>
                </div>
              )}
            </div>

            {/* Content */}
            <div style={{
              fontSize: '1rem', 
              lineHeight: '1.8', 
              color: 'var(--text-primary)',
              whiteSpace: 'pre-wrap',
              wordWrap: 'break-word',
              marginBottom: '2rem'
            }}>
              {notice.content}
            </div>

            {/* Actions */}
            <div style={{display: 'flex', gap: '1rem', paddingTop: '1.5rem', borderTop: '1px solid var(--border-color)'}}>
              <Button 
                variant="secondary" 
                onClick={() => navigate('/department/notices')}
                style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}
              >
                <ArrowLeft size={16} />
                Back to Notices
              </Button>
              
              {notice.status === 'DRAFT' && (
                <Button 
                  variant="primary"
                  onClick={handlePublish}
                  disabled={publishing}
                  style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginLeft: 'auto'}}
                >
                  {publishing ? (
                    <>
                      <RefreshCw size={16} className="animate-spin" />
                      Publishing...
                    </>
                  ) : (
                    <>
                      <Send size={16} />
                      Publish Notice
                    </>
                  )}
                </Button>
              )}
            </div>
          </Card>
        )}
      </div>
    </DepartmentDashboardLayout>
  );
};
