import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Calendar, User, AlertCircle, CheckCircle, RefreshCw, Building2, Play, Upload, Star, MessageSquare } from 'lucide-react';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const DepartmentIssueDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [issue, setIssue] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [processing, setProcessing] = useState(false);
  
  // Feedback state
  const [feedbackData, setFeedbackData] = useState(null);
  
  // Resolve form state
  const [showResolveForm, setShowResolveForm] = useState(false);
  const [resolutionDescription, setResolutionDescription] = useState('');
  const [evidenceFile, setEvidenceFile] = useState(null);
  const [evidencePreview, setEvidencePreview] = useState(null);

  useEffect(() => {
    fetchIssueDetails();
  }, [id]);

  const fetchIssueDetails = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get(`/issues/${id}`);
      setIssue(res.issue);
      
      // If resolved, try to fetch feedback
      if (res.issue.status === 'RESOLVED') {
        try {
          const feedbackRes = await api.get(`/issues/${id}/feedback`);
          setFeedbackData(feedbackRes.feedback);
        } catch (err) {
          // If 404, no feedback exists yet - this is fine
          if (err.status !== 404) {
            console.error("Error fetching feedback", err);
          }
        }
      }
    } catch (err) {
      setError('Unable to load issue details.');
    } finally {
      setLoading(false);
    }
  };

  const handleStartIssue = async () => {
    if (!window.confirm('Are you sure you want to start working on this issue?')) {
      return;
    }

    setProcessing(true);
    try {
      const res = await api.patch(`/issues/${id}/start`);
      setIssue(res.issue);
      alert('Issue moved to IN PROGRESS!');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to start issue.');
    } finally {
      setProcessing(false);
    }
  };

  const handleEvidenceChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        alert('File size must be less than 5MB');
        return;
      }
      if (!file.type.startsWith('image/')) {
        alert('Only image files are allowed');
        return;
      }
      setEvidenceFile(file);
      setEvidencePreview(URL.createObjectURL(file));
    }
  };

  const handleResolveIssue = async (e) => {
    e.preventDefault();

    if (!resolutionDescription.trim()) {
      alert('Please enter a resolution description.');
      return;
    }

    if (!evidenceFile) {
      alert('Please upload resolution evidence.');
      return;
    }

    setProcessing(true);
    try {
      const formData = new FormData();
      formData.append('resolution_description', resolutionDescription.trim());
      formData.append('evidence', evidenceFile);

      // Important: Do NOT set Content-Type header - let browser set it with boundary
      const res = await api.patch(`/issues/${id}/resolve`, formData);
      
      setIssue(res.issue);
      setShowResolveForm(false);
      alert('Issue resolved successfully!');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to resolve issue.');
    } finally {
      setProcessing(false);
    }
  };

  const getStatusBadge = (status) => {
    switch(status) {
      case 'ASSIGNED': return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>ASSIGNED</span>;
      case 'IN_PROGRESS': return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>IN PROGRESS</span>;
      case 'RESOLVED': return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>RESOLVED</span>;
      default: return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>{status}</span>;
    }
  };

  if (loading) {
    return (
      <DepartmentDashboardLayout>
        <Card style={{padding: '3rem', textAlign: 'center'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--text-secondary)'}}>
            <RefreshCw size={32} className="animate-spin" />
            <p>Loading issue details...</p>
          </div>
        </Card>
      </DepartmentDashboardLayout>
    );
  }

  if (error || !issue) {
    return (
      <DepartmentDashboardLayout>
        <Card style={{padding: '3rem', textAlign: 'center'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Issue</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error || 'Issue not found'}</p>
            </div>
            <div style={{display: 'flex', gap: '1rem', marginTop: '1rem'}}>
              <Button variant="outline" onClick={() => navigate('/department/issues')} style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                <ArrowLeft size={16} />
                Back to Issues
              </Button>
              <Button variant="outline" onClick={fetchIssueDetails} style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                <RefreshCw size={16} />
                Retry
              </Button>
            </div>
          </div>
        </Card>
      </DepartmentDashboardLayout>
    );
  }

  const canStart = issue.status === 'ASSIGNED';
  const canResolve = issue.status === 'IN_PROGRESS';
  const isResolved = issue.status === 'RESOLVED';

  return (
    <DepartmentDashboardLayout>
      <div style={{marginBottom: '1.5rem'}}>
        <Button 
          variant="ghost" 
          onClick={() => navigate('/department/issues')}
          style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem'}}
        >
          <ArrowLeft size={16} />
          Back to Issues
        </Button>
        
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '1rem', flexWrap: 'wrap'}}>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
            Issue Details
          </h1>
          {getStatusBadge(issue.status)}
        </div>
      </div>

      <div style={{display: 'grid', gridTemplateColumns: showResolveForm ? '1fr 400px' : '1fr', gap: '1.5rem'}}>
        {/* Issue Details */}
        <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
          <Card style={{padding: '1.5rem'}}>
            <h2 style={{margin: '0 0 1rem 0', fontSize: '1.25rem', fontWeight: '600', color: 'var(--text-primary)'}}>
              {issue.title}
            </h2>

            <div style={{display: 'grid', gap: '1rem', marginBottom: '1.5rem'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)'}}>Category:</div>
                <div style={{color: 'var(--text-primary)'}}>{issue.category}</div>
              </div>

              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <MapPin size={14} />
                  Location:
                </div>
                <div style={{color: 'var(--text-primary)'}}>{issue.location}</div>
              </div>

              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <User size={14} />
                  Reported By:
                </div>
                <div style={{color: 'var(--text-primary)'}}>
                  {issue.reportedBy?.name || 'Unknown'}
                </div>
              </div>

              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <Calendar size={14} />
                  Reported On:
                </div>
                <div style={{color: 'var(--text-primary)'}}>
                  {new Date(issue.createdAt).toLocaleString()}
                </div>
              </div>

              {issue.department && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                    <Building2 size={14} />
                    Department:
                  </div>
                  <div style={{color: 'var(--text-primary)'}}>
                    {issue.department.name}
                  </div>
                </div>
              )}
            </div>

            <div style={{marginBottom: '1.5rem'}}>
              <h3 style={{margin: '0 0 0.5rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)'}}>
                Description
              </h3>
              <p style={{margin: 0, color: 'var(--text-secondary)', lineHeight: '1.6'}}>
                {issue.description}
              </p>
            </div>

            {issue.image_url && (
              <div>
                <h3 style={{margin: '0 0 0.5rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)'}}>
                  Evidence Photo
                </h3>
                <img 
                  src={issue.image_url} 
                  alt="Issue evidence" 
                  style={{
                    width: '100%', 
                    maxWidth: '600px',
                    height: 'auto',
                    borderRadius: '8px',
                    border: '1px solid var(--border-color)'
                  }}
                />
              </div>
            )}
          </Card>

          {/* Resolution Details (if resolved) */}
          {isResolved && issue.resolution_description && (
            <Card style={{padding: '1.5rem', backgroundColor: 'var(--success-50)', borderColor: 'var(--success-200)'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem', color: 'var(--success-700)'}}>
                <CheckCircle size={20} />
                <h3 style={{margin: 0, fontSize: '1rem', fontWeight: '600'}}>Resolved</h3>
              </div>
              <p style={{margin: '0 0 1rem 0', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                <strong>Resolution Description:</strong><br />
                {issue.resolution_description}
              </p>
              {issue.resolution_evidence && (
                <>
                  <p style={{margin: '0 0 0.5rem 0', color: 'var(--text-secondary)', fontSize: '0.875rem', fontWeight: '600'}}>
                    Resolution Evidence:
                  </p>
                  <img 
                    src={issue.resolution_evidence} 
                    alt="Resolution evidence" 
                    style={{
                      width: '100%', 
                      maxWidth: '400px',
                      height: 'auto',
                      borderRadius: '8px',
                      border: '1px solid var(--success-200)'
                    }}
                  />
                </>
              )}
              {issue.resolvedAt && (
                <p style={{margin: '1rem 0 0 0', color: 'var(--text-tertiary)', fontSize: '0.875rem'}}>
                  Resolved on: {new Date(issue.resolvedAt).toLocaleString()}
                </p>
              )}
            </Card>
          )}

          {/* Citizen Feedback - Display only for RESOLVED issues */}
          {isResolved && feedbackData && (
            <Card style={{padding: '1.5rem', backgroundColor: 'var(--primary-50)', borderColor: 'var(--primary-200)'}}>
              <h3 style={{margin: '0 0 1rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                <Star size={20} />
                Citizen Feedback
              </h3>
              <div>
                <div style={{display: 'flex', alignItems: 'center', gap: '0.25rem', marginBottom: '1rem'}}>
                  {[1, 2, 3, 4, 5].map(star => (
                    <Star 
                      key={star} 
                      size={24} 
                      fill={star <= feedbackData.rating ? 'var(--warning-500)' : 'none'} 
                      color={star <= feedbackData.rating ? 'var(--warning-500)' : 'var(--border-color)'} 
                    />
                  ))}
                </div>
                {feedbackData.comment && (
                  <div style={{display: 'flex', alignItems: 'flex-start', gap: '0.5rem', padding: '1rem', backgroundColor: 'var(--bg-surface)', borderRadius: 'var(--border-radius-sm)'}}>
                    <MessageSquare size={16} style={{color: 'var(--text-secondary)', marginTop: '2px', flexShrink: 0}} />
                    <p style={{color: 'var(--text-secondary)', margin: 0}}>{feedbackData.comment}</p>
                  </div>
                )}
                <p style={{fontSize: '0.75rem', color: 'var(--text-tertiary)', marginTop: '1rem', marginBottom: 0}}>
                  Submitted on {new Date(feedbackData.createdAt).toLocaleString()}
                </p>
              </div>
            </Card>
          )}

          {isResolved && !feedbackData && (
            <Card style={{padding: '1.5rem', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                <Star size={18} />
                <span>No citizen feedback yet</span>
              </div>
            </Card>
          )}

          {/* Action Buttons */}
          {!isResolved && (
            <Card style={{padding: '1.5rem'}}>
              <h3 style={{margin: '0 0 1rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)'}}>
                Actions
              </h3>
              <div style={{display: 'flex', gap: '1rem', flexWrap: 'wrap'}}>
                {canStart && (
                  <Button
                    variant="primary"
                    onClick={handleStartIssue}
                    disabled={processing}
                    style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}
                  >
                    {processing ? (
                      <>
                        <RefreshCw size={16} className="animate-spin" />
                        Starting...
                      </>
                    ) : (
                      <>
                        <Play size={16} />
                        Start Work
                      </>
                    )}
                  </Button>
                )}

                {canResolve && !showResolveForm && (
                  <Button
                    variant="primary"
                    onClick={() => setShowResolveForm(true)}
                    style={{display: 'flex', alignItems: 'center', gap: '0.5rem', backgroundColor: 'var(--success-600)'}}
                  >
                    <CheckCircle size={16} />
                    Resolve Issue
                  </Button>
                )}

                {canResolve && showResolveForm && (
                  <Button
                    variant="secondary"
                    onClick={() => {
                      setShowResolveForm(false);
                      setResolutionDescription('');
                      setEvidenceFile(null);
                      setEvidencePreview(null);
                    }}
                  >
                    Cancel
                  </Button>
                )}
              </div>
            </Card>
          )}
        </div>

        {/* Resolve Form */}
        {showResolveForm && (
          <Card style={{padding: '1.5rem', height: 'fit-content'}}>
            <h3 style={{margin: '0 0 1rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--success-600)'}}>
              Resolve Issue
            </h3>

            <form onSubmit={handleResolveIssue}>
              <div style={{marginBottom: '1rem'}}>
                <label htmlFor="resolution" className="form-label">
                  Resolution Description <span style={{color: 'var(--danger-600)'}}>*</span>
                </label>
                <textarea
                  id="resolution"
                  className="input-field"
                  rows={5}
                  placeholder="Describe how the issue was resolved..."
                  value={resolutionDescription}
                  onChange={(e) => setResolutionDescription(e.target.value)}
                  disabled={processing}
                  required
                />
              </div>

              <div style={{marginBottom: '1.5rem'}}>
                <label htmlFor="evidence" className="form-label">
                  Resolution Evidence <span style={{color: 'var(--danger-600)'}}>*</span>
                </label>
                <input
                  id="evidence"
                  type="file"
                  accept="image/*"
                  onChange={handleEvidenceChange}
                  disabled={processing}
                  style={{display: 'none'}}
                />
                <label
                  htmlFor="evidence"
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    padding: '1rem',
                    border: '2px dashed var(--border-color)',
                    borderRadius: 'var(--border-radius-md)',
                    cursor: 'pointer',
                    backgroundColor: 'var(--bg-secondary)',
                    transition: 'all 0.2s'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.borderColor = 'var(--primary-500)'}
                  onMouseLeave={(e) => e.currentTarget.style.borderColor = 'var(--border-color)'}
                >
                  <Upload size={20} />
                  <span>{evidenceFile ? evidenceFile.name : 'Click to upload image'}</span>
                </label>

                {evidencePreview && (
                  <div style={{marginTop: '1rem'}}>
                    <img
                      src={evidencePreview}
                      alt="Evidence preview"
                      style={{
                        width: '100%',
                        height: 'auto',
                        maxHeight: '200px',
                        objectFit: 'contain',
                        borderRadius: 'var(--border-radius-md)',
                        border: '1px solid var(--border-color)'
                      }}
                    />
                  </div>
                )}
              </div>

              <Button
                type="submit"
                variant="primary"
                disabled={processing || !resolutionDescription.trim() || !evidenceFile}
                style={{width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', backgroundColor: 'var(--success-600)'}}
              >
                {processing ? (
                  <>
                    <RefreshCw size={16} className="animate-spin" />
                    Resolving...
                  </>
                ) : (
                  <>
                    <CheckCircle size={16} />
                    Submit Resolution
                  </>
                )}
              </Button>
            </form>
          </Card>
        )}
      </div>
    </DepartmentDashboardLayout>
  );
};
