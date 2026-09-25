import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Calendar, Clock, CheckCircle2, AlertCircle, Building, User, FileText, Image as ImageIcon, Star, MessageSquare } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

const STATUS_ORDER = ['REPORTED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED'];

export const IssueDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [issue, setIssue] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Feedback state
  const [feedbackData, setFeedbackData] = useState(null);
  const [submittingFeedback, setSubmittingFeedback] = useState(false);
  const [feedbackForm, setFeedbackForm] = useState({ rating: 5, comment: '' });

  useEffect(() => {
    fetchIssueDetails();
  }, [id]);

  const fetchIssueDetails = async () => {
    try {
      const res = await api.get(`/issues/${id}`);
      setIssue(res.issue);
      
      // If resolved, check for existing feedback
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
      setError('Failed to load issue details.');
    } finally {
      setLoading(false);
    }
  };

  const handleFeedbackSubmit = async (e) => {
    e.preventDefault();
    setSubmittingFeedback(true);
    try {
      await api.post('/feedback', {
        issue_id: id,
        rating: feedbackForm.rating,
        comment: feedbackForm.comment.trim() || null
      });
      // Re-fetch to get updated feedback
      await fetchIssueDetails();
      alert('Feedback submitted successfully!');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to submit feedback.');
    } finally {
      setSubmittingFeedback(false);
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div style={{display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh'}}>
          Loading issue details...
        </div>
      </DashboardLayout>
    );
  }

  if (error || !issue) {
    return (
      <DashboardLayout>
        <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Issue</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error || 'Issue not found'}</p>
            </div>
            <Button variant="outline" onClick={() => navigate('/citizen/my-issues')} style={{marginTop: '1rem'}}>
              Back to My Issues
            </Button>
          </div>
        </Card>
      </DashboardLayout>
    );
  }

  const isRejected = issue.status === 'REJECTED';
  const timelineStatuses = isRejected ? ['REPORTED', 'REJECTED'] : STATUS_ORDER;
  const currentStatusIndex = timelineStatuses.indexOf(issue.status);

  return (
    <DashboardLayout>
      <div style={{maxWidth: '1000px', margin: '0 auto'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem'}}>
          <button 
            onClick={() => navigate('/citizen/my-issues')}
            style={{background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', color: 'var(--text-secondary)'}}
          >
            <ArrowLeft size={20} />
          </button>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
            Issue Details
          </h1>
        </div>

        <div style={{display: 'grid', gridTemplateColumns: '1fr 350px', gap: '1.5rem', alignItems: 'start'}}>
          <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
            <Card style={{padding: '1.5rem'}}>
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem'}}>
                <div>
                  <div style={{display: 'inline-block', backgroundColor: 'var(--bg-secondary)', padding: '0.25rem 0.5rem', borderRadius: '4px', fontSize: '0.75rem', fontWeight: '600', color: 'var(--text-secondary)', marginBottom: '0.5rem'}}>
                    {issue.category}
                  </div>
                  <h2 style={{margin: '0 0 0.5rem 0', fontSize: '1.5rem', color: 'var(--text-primary)'}}>{issue.title}</h2>
                  <div style={{display: 'flex', gap: '1.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                    <span style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                      <Calendar size={16} />
                      Reported {new Date(issue.createdAt).toLocaleDateString()}
                    </span>
                    <span style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                      <MapPin size={16} />
                      {issue.location}
                    </span>
                  </div>
                </div>
              </div>

              <div style={{borderTop: '1px solid var(--border-color)', paddingTop: '1.5rem', marginBottom: '1.5rem'}}>
                <h3 style={{fontSize: '1rem', fontWeight: '600', marginBottom: '0.5rem'}}>Description</h3>
                <p style={{color: 'var(--text-secondary)', whiteSpace: 'pre-wrap', margin: 0, lineHeight: 1.6}}>
                  {issue.description}
                </p>
              </div>

              {issue.image_url && (
                <div style={{borderTop: '1px solid var(--border-color)', paddingTop: '1.5rem'}}>
                  <h3 style={{fontSize: '1rem', fontWeight: '600', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                    <ImageIcon size={18} />
                    Attached Photo
                  </h3>
                  <img 
                    src={issue.image_url} 
                    alt="Issue evidence" 
                    style={{maxWidth: '100%', maxHeight: '400px', borderRadius: 'var(--border-radius-md)', border: '1px solid var(--border-color)'}} 
                  />
                </div>
              )}
            </Card>

            {issue.status === 'RESOLVED' && (
              <Card style={{padding: '1.5rem', backgroundColor: 'var(--success-50)', borderColor: 'var(--success-200)'}}>
                <h3 style={{fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem', color: 'var(--success-800)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <CheckCircle2 size={20} />
                  Resolution Details
                </h3>
                
                <p style={{color: 'var(--success-900)', whiteSpace: 'pre-wrap', marginBottom: '1.5rem', lineHeight: 1.6}}>
                  {issue.resolution_description || 'This issue has been resolved by the department.'}
                </p>
                
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--success-700)', fontSize: '0.875rem', marginBottom: issue.resolution_evidence ? '1.5rem' : '0'}}>
                  <Clock size={16} />
                  Resolved on {issue.resolvedAt ? new Date(issue.resolvedAt).toLocaleDateString() : 'N/A'}
                </div>

                {issue.resolution_evidence && (
                  <div>
                    <h4 style={{fontSize: '0.875rem', fontWeight: '600', color: 'var(--success-800)', marginBottom: '0.5rem'}}>Resolution Evidence</h4>
                    <img 
                      src={issue.resolution_evidence} 
                      alt="Resolution evidence" 
                      style={{maxWidth: '100%', maxHeight: '300px', borderRadius: 'var(--border-radius-md)', border: '1px solid var(--success-200)'}} 
                    />
                  </div>
                )}
              </Card>
            )}

            {/* Feedback Section - Only show for RESOLVED issues */}
            {issue.status === 'RESOLVED' && (
              <Card style={{padding: '1.5rem'}}>
                <h3 style={{fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <Star size={20} />
                  Issue Feedback
                </h3>
                
                {feedbackData ? (
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
                      <div style={{display: 'flex', alignItems: 'flex-start', gap: '0.5rem', padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: 'var(--border-radius-sm)'}}>
                        <MessageSquare size={16} style={{color: 'var(--text-secondary)', marginTop: '2px', flexShrink: 0}} />
                        <p style={{color: 'var(--text-secondary)', margin: 0}}>{feedbackData.comment}</p>
                      </div>
                    )}
                    <p style={{fontSize: '0.75rem', color: 'var(--text-tertiary)', marginTop: '1rem', marginBottom: 0}}>
                      Submitted on {new Date(feedbackData.createdAt).toLocaleString()}
                    </p>
                  </div>
                ) : (
                  <form onSubmit={handleFeedbackSubmit} style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
                    <div>
                      <label style={{display: 'block', fontSize: '0.875rem', fontWeight: '500', marginBottom: '0.5rem'}}>
                        Rate this resolution <span style={{color: 'var(--danger-600)'}}>*</span>
                      </label>
                      <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                        {[1, 2, 3, 4, 5].map(star => (
                          <button
                            key={star}
                            type="button"
                            onClick={() => setFeedbackForm({...feedbackForm, rating: star})}
                            style={{background: 'none', border: 'none', cursor: 'pointer', padding: 0, transition: 'transform 0.2s'}}
                            onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.1)'}
                            onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
                          >
                            <Star 
                              size={32} 
                              fill={star <= feedbackForm.rating ? 'var(--warning-500)' : 'none'} 
                              color={star <= feedbackForm.rating ? 'var(--warning-500)' : 'var(--border-color)'} 
                            />
                          </button>
                        ))}
                      </div>
                    </div>
                    
                    <div>
                      <label style={{display: 'block', fontSize: '0.875rem', fontWeight: '500', marginBottom: '0.5rem'}}>
                        Your Feedback (Optional)
                      </label>
                      <textarea
                        value={feedbackForm.comment}
                        onChange={(e) => setFeedbackForm({...feedbackForm, comment: e.target.value})}
                        className="input-field"
                        rows={3}
                        placeholder="Share your experience with the resolution..."
                        disabled={submittingFeedback}
                        maxLength={1000}
                      />
                      <p style={{fontSize: '0.75rem', color: 'var(--text-tertiary)', marginTop: '0.25rem', marginBottom: 0}}>
                        {feedbackForm.comment.length}/1000 characters
                      </p>
                    </div>
                    
                    <div>
                      <Button 
                        type="submit" 
                        variant="primary" 
                        disabled={submittingFeedback}
                        style={{width: '100%'}}
                      >
                        {submittingFeedback ? 'Submitting...' : 'Submit Feedback'}
                      </Button>
                    </div>
                  </form>
                )}
              </Card>
            )}
          </div>

          <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
            {/* Status Timeline */}
            <Card style={{padding: '1.5rem'}}>
              <h3 style={{fontSize: '1.125rem', fontWeight: '600', marginBottom: '1.5rem', color: 'var(--text-primary)'}}>
                Status Timeline
              </h3>
              
              <div style={{display: 'flex', flexDirection: 'column', gap: '0'}}>
                {timelineStatuses.map((status, index) => {
                  const isCompleted = index < currentStatusIndex;
                  const isCurrent = index === currentStatusIndex;
                  const isUpcoming = index > currentStatusIndex;
                  
                  let iconBg = 'var(--bg-secondary)';
                  let iconColor = 'var(--text-secondary)';
                  let titleColor = 'var(--text-secondary)';
                  let descText = 'Upcoming';
                  let Icon = Clock;
                  
                  if (isCompleted) {
                    iconBg = 'var(--primary-100)';
                    iconColor = 'var(--primary-600)';
                    titleColor = 'var(--text-primary)';
                    descText = 'Completed';
                    Icon = CheckCircle2;
                  } else if (isCurrent) {
                    if (status === 'REJECTED') {
                      iconBg = 'var(--danger-100)';
                      iconColor = 'var(--danger-600)';
                      titleColor = 'var(--danger-600)';
                      descText = 'Rejected';
                      Icon = AlertCircle;
                    } else if (status === 'RESOLVED') {
                      iconBg = 'var(--success-100)';
                      iconColor = 'var(--success-600)';
                      titleColor = 'var(--success-600)';
                      descText = 'Completed';
                      Icon = CheckCircle2;
                    } else {
                      iconBg = 'var(--primary-600)';
                      iconColor = 'white';
                      titleColor = 'var(--primary-600)';
                      descText = 'Current Phase';
                      Icon = Clock;
                    }
                  }

                  return (
                    <div key={status} style={{display: 'flex', gap: '1rem', position: 'relative'}}>
                      {/* Vertical line connecting nodes */}
                      {index < timelineStatuses.length - 1 && (
                        <div style={{
                          position: 'absolute', 
                          left: '11px', 
                          top: '24px', 
                          bottom: '-10px', 
                          width: '2px', 
                          backgroundColor: isCompleted ? 'var(--primary-600)' : 'var(--border-color)',
                          zIndex: 0
                        }} />
                      )}
                      
                      <div style={{
                        width: '24px', 
                        height: '24px', 
                        borderRadius: '50%', 
                        backgroundColor: iconBg, 
                        color: iconColor, 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center', 
                        zIndex: 1,
                        flexShrink: 0
                      }}>
                        <Icon size={14} />
                      </div>
                      
                      <div style={{paddingBottom: '2rem'}}>
                        <div style={{fontWeight: '600', fontSize: '0.875rem', color: titleColor, lineHeight: 1}}>{status.replace('_', ' ')}</div>
                        <div style={{fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: '0.25rem'}}>{descText}</div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </Card>

            {/* Department Info if assigned */}
            {issue.department && (
              <Card style={{padding: '1.5rem'}}>
                <h3 style={{fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <Building size={18} />
                  Assigned Department
                </h3>
                <div style={{display: 'flex', flexDirection: 'column', gap: '0.75rem'}}>
                  <div style={{fontWeight: '500', color: 'var(--text-primary)'}}>{issue.department.name}</div>
                  {issue.department.office_address && (
                    <div style={{display: 'flex', alignItems: 'flex-start', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                      <MapPin size={16} style={{flexShrink: 0, marginTop: '2px'}} />
                      <span>{issue.department.office_address}</span>
                    </div>
                  )}
                  {issue.department.mobile && (
                    <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                      <FileText size={16} style={{flexShrink: 0}} />
                      <span>Contact: {issue.department.mobile}</span>
                    </div>
                  )}
                </div>
              </Card>
            )}
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};
