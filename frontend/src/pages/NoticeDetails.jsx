import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Calendar, User, AlertCircle, RefreshCw, Megaphone } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const NoticeDetails = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const [notice, setNotice] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

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

  const getCategoryBadge = (category) => {
    switch(category) {
      case 'EMERGENCY': 
        return <span style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>EMERGENCY</span>;
      case 'MAINTENANCE': 
        return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>MAINTENANCE</span>;
      case 'EVENT': 
        return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>EVENT</span>;
      case 'POLICY': 
        return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>POLICY</span>;
      case 'ANNOUNCEMENT': 
        return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>ANNOUNCEMENT</span>;
      case 'GENERAL':
        return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>GENERAL</span>;
      default: 
        return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.5rem 1rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>{category}</span>;
    }
  };

  const formatDateTime = (dateString) => {
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
    <DashboardLayout>
      <div style={{maxWidth: '900px', margin: '0 auto'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem'}}>
          <button 
            onClick={() => navigate('/citizen/notices')}
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
          <Card style={{padding: '2rem'}}>
            <div style={{height: '32px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '30%', marginBottom: '1.5rem'}} />
            <div style={{height: '40px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '80%', marginBottom: '1rem'}} />
            <div style={{height: '20px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '40%', marginBottom: '2rem'}} />
            <div style={{height: '120px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '100%'}} />
          </Card>
        ) : !notice ? (
          <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--text-secondary)'}}>
              <Megaphone size={48} />
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Notice not found</h3>
              <Button variant="primary" onClick={() => navigate('/citizen/notices')}>
                Back to Notices
              </Button>
            </div>
          </Card>
        ) : (
          <Card style={{padding: '2rem'}}>
            {/* Category Badge */}
            <div style={{marginBottom: '1.5rem'}}>
              {getCategoryBadge(notice.category)}
            </div>

            {/* Title */}
            <h2 style={{fontSize: '2.5rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '1.5rem', lineHeight: '1.3'}}>
              {notice.title}
            </h2>

            {/* Meta Information */}
            <div style={{display: 'flex', flexWrap: 'wrap', gap: '1.5rem', marginBottom: '2rem', paddingBottom: '1.5rem', borderBottom: '1px solid var(--border-color)'}}>
              {notice.department && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <User size={16} />
                  <span><strong>Department:</strong> {notice.department.name}</span>
                </div>
              )}
              
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                <Calendar size={16} />
                <span><strong>Published:</strong> {formatDateTime(notice.publishedAt)}</span>
              </div>

              {notice.startDate && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <Calendar size={16} />
                  <span><strong>Valid From:</strong> {formatDateOnly(notice.startDate)}</span>
                </div>
              )}

              {notice.endDate && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <Calendar size={16} />
                  <span><strong>Valid Until:</strong> {formatDateOnly(notice.endDate)}</span>
                </div>
              )}
            </div>

            {/* Content */}
            <div style={{
              fontSize: '1rem', 
              lineHeight: '1.8', 
              color: 'var(--text-primary)',
              whiteSpace: 'pre-wrap',
              wordWrap: 'break-word'
            }}>
              {notice.content}
            </div>

            {/* Back Button */}
            <div style={{marginTop: '2rem', paddingTop: '1.5rem', borderTop: '1px solid var(--border-color)'}}>
              <Button 
                variant="secondary" 
                onClick={() => navigate('/citizen/notices')}
                style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}
              >
                <ArrowLeft size={16} />
                Back to Public Notices
              </Button>
            </div>
          </Card>
        )}
      </div>
    </DashboardLayout>
  );
};
