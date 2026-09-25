import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Calendar, Clock, CheckCircle2, AlertCircle, Building, FileText, Ban, Star, MessageSquare } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

const STATUS_ORDER = ['PENDING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED'];

export const ServiceRequestDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const [requestData, setRequestData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  const [cancelling, setCancelling] = useState(false);
  const [showCancelConfirm, setShowCancelConfirm] = useState(false);
  
  const [feedbackData, setFeedbackData] = useState(null);
  const [submittingFeedback, setSubmittingFeedback] = useState(false);
  const [feedbackForm, setFeedbackForm] = useState({ rating: 5, comment: '' });

  useEffect(() => {
    fetchRequestDetails();
  }, [id]);

  const fetchRequestDetails = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get(`/services/requests/${id}`);
      setRequestData(res.serviceRequest);
      
      // If completed, check for feedback
      if (res.serviceRequest.status === 'COMPLETED') {
        try {
          const feedbackRes = await api.get(`/services/requests/${id}/feedback`);
          setFeedbackData(feedbackRes.feedback);
        } catch (err) {
          // If 404, it means no feedback exists yet. Ignore other errors.
          if (err.status !== 404) {
             console.error("Error fetching feedback", err);
          }
        }
      }
    } catch (err) {
      setError('Failed to load service request details.');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async () => {
    setCancelling(true);
    try {
      await api.patch(`/services/requests/${id}/cancel`, {});
      await fetchRequestDetails();
      setShowCancelConfirm(false);
    } catch (err) {
      setError(err.message || 'Failed to cancel the request.');
    } finally {
      setCancelling(false);
    }
  };

  const handleFeedbackSubmit = async (e) => {
    e.preventDefault();
    setSubmittingFeedback(true);
    try {
      await api.post(`/services/requests/${id}/feedback`, feedbackForm);
      await fetchRequestDetails();
    } catch (err) {
      setError(err.message || 'Failed to submit feedback.');
    } finally {
      setSubmittingFeedback(false);
    }
  };

  if (loading) {
    return (
      <DashboardLayout>
        <div style={{display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh'}}>
          Loading request details...
        </div>
      </DashboardLayout>
    );
  }

  if (error && !requestData) {
    return (
      <DashboardLayout>
        <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Request</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error}</p>
            </div>
            <Button variant="outline" onClick={() => navigate('/citizen/my-requests')} style={{marginTop: '1rem'}}>
              Back to My Requests
            </Button>
          </div>
        </Card>
      </DashboardLayout>
    );
  }

  const isRejected = requestData.status === 'REJECTED';
  const isCancelled = requestData.status === 'CANCELLED';
  
  let timelineStatuses = STATUS_ORDER;
  if (isRejected) timelineStatuses = ['PENDING', 'REJECTED'];
  if (isCancelled) timelineStatuses = ['PENDING', 'CANCELLED'];
  
  const currentStatusIndex = timelineStatuses.indexOf(requestData.status);

  return (
    <DashboardLayout>
      <div style={{maxWidth: '1000px', margin: '0 auto'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem'}}>
          <button 
            onClick={() => navigate('/citizen/my-requests')}
            style={{background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', color: 'var(--text-secondary)'}}
          >
            <ArrowLeft size={20} />
          </button>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
            Service Request Details
          </h1>
        </div>

        {error && (
          <div style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.75rem', borderRadius: 'var(--border-radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem'}}>
            {error}
          </div>
        )}

        <div style={{display: 'grid', gridTemplateColumns: '1fr 350px', gap: '1.5rem', alignItems: 'start'}}>
          <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
            <Card style={{padding: '1.5rem'}}>
              <div style={{marginBottom: '1.5rem'}}>
                <div style={{display: 'inline-block', backgroundColor: 'var(--bg-secondary)', padding: '0.25rem 0.5rem', borderRadius: '4px', fontSize: '0.75rem', fontWeight: '600', color: 'var(--text-secondary)', marginBottom: '0.5rem'}}>
                  {requestData.service?.category.replace(/_/g, ' ')}
                </div>
                <h2 style={{margin: '0 0 0.5rem 0', fontSize: '1.5rem', color: 'var(--text-primary)'}}>
                  {requestData.service?.name}
                </h2>
                <div style={{display: 'flex', gap: '1.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <span style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                    <Calendar size={16} />
                    Requested on {new Date(requestData.createdAt).toLocaleDateString()}
                  </span>
                </div>
              </div>

              <div style={{borderTop: '1px solid var(--border-color)', paddingTop: '1.5rem'}}>
                <h3 style={{fontSize: '1rem', fontWeight: '600', marginBottom: '0.5rem'}}>Additional Notes</h3>
                {requestData.notes ? (
                  <p style={{color: 'var(--text-secondary)', whiteSpace: 'pre-wrap', margin: 0, lineHeight: 1.6, padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: 'var(--border-radius-sm)'}}>
                    {requestData.notes}
                  </p>
                ) : (
                  <p style={{color: 'var(--text-secondary)', fontStyle: 'italic', margin: 0}}>No additional notes provided.</p>
                )}
              </div>
            </Card>

            {isRejected && requestData.rejectionReason && (
              <Card style={{padding: '1.5rem', backgroundColor: 'var(--danger-50)', borderColor: 'var(--danger-200)'}}>
                <h3 style={{fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem', color: 'var(--danger-800)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <AlertCircle size={20} />
                  Rejection Reason
                </h3>
                <p style={{color: 'var(--danger-900)', margin: 0, lineHeight: 1.6}}>
                  {requestData.rejectionReason}
                </p>
              </Card>
            )}

            {requestData.status === 'COMPLETED' && (
              <Card style={{padding: '1.5rem'}}>
                <h3 style={{fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <Star size={20} />
                  Service Feedback
                </h3>
                
                {feedbackData ? (
                  <div>
                    <div style={{display: 'flex', alignItems: 'center', gap: '0.25rem', marginBottom: '1rem'}}>
                      {[1, 2, 3, 4, 5].map(star => (
                        <Star key={star} size={24} fill={star <= feedbackData.rating ? 'var(--warning-500)' : 'none'} color={star <= feedbackData.rating ? 'var(--warning-500)' : 'var(--border-color)'} />
                      ))}
                    </div>
                    {feedbackData.comment && (
                      <div style={{display: 'flex', alignItems: 'flex-start', gap: '0.5rem', padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: 'var(--border-radius-sm)'}}>
                        <MessageSquare size={16} style={{color: 'var(--text-secondary)', marginTop: '2px', flexShrink: 0}} />
                        <p style={{color: 'var(--text-secondary)', margin: 0}}>{feedbackData.comment}</p>
                      </div>
                    )}
                  </div>
                ) : (
                  <form onSubmit={handleFeedbackSubmit} style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
                    <div>
                      <label style={{display: 'block', fontSize: '0.875rem', fontWeight: '500', marginBottom: '0.5rem'}}>Rate your experience</label>
                      <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                        {[1, 2, 3, 4, 5].map(star => (
                          <button
                            key={star}
                            type="button"
                            onClick={() => setFeedbackForm({...feedbackForm, rating: star})}
                            style={{background: 'none', border: 'none', cursor: 'pointer', padding: 0}}
                          >
                            <Star size={32} fill={star <= feedbackForm.rating ? 'var(--warning-500)' : 'none'} color={star <= feedbackForm.rating ? 'var(--warning-500)' : 'var(--border-color)'} />
                          </button>
                        ))}
                      </div>
                    </div>
                    <div>
                      <label style={{display: 'block', fontSize: '0.875rem', fontWeight: '500', marginBottom: '0.5rem'}}>Comments (Optional)</label>
                      <textarea
                        value={feedbackForm.comment}
                        onChange={(e) => setFeedbackForm({...feedbackForm, comment: e.target.value})}
                        className="input-field"
                        rows={3}
                        placeholder="Tell us about your experience..."
                      />
                    </div>
                    <div>
                      <Button type="submit" variant="primary" disabled={submittingFeedback}>
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
                    } else if (status === 'CANCELLED') {
                      iconBg = 'var(--bg-secondary)';
                      iconColor = 'var(--text-secondary)';
                      titleColor = 'var(--text-secondary)';
                      descText = 'Cancelled';
                      Icon = Ban;
                    } else if (status === 'COMPLETED') {
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

              {requestData.status === 'PENDING' && (
                <div style={{marginTop: '1rem', paddingTop: '1rem', borderTop: '1px solid var(--border-color)'}}>
                  {showCancelConfirm ? (
                    <div style={{display: 'flex', flexDirection: 'column', gap: '0.75rem'}}>
                      <span style={{fontSize: '0.875rem', color: 'var(--text-primary)', fontWeight: '500'}}>Are you sure you want to cancel?</span>
                      <div style={{display: 'flex', gap: '0.5rem'}}>
                        <Button variant="outline" style={{flex: 1}} onClick={() => setShowCancelConfirm(false)}>No</Button>
                        <Button variant="primary" style={{flex: 1, backgroundColor: 'var(--danger-600)', borderColor: 'var(--danger-600)'}} onClick={handleCancel} disabled={cancelling}>
                          {cancelling ? 'Cancelling...' : 'Yes, Cancel'}
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <Button variant="outline" style={{width: '100%', color: 'var(--danger-600)', borderColor: 'var(--danger-200)'}} onClick={() => setShowCancelConfirm(true)}>
                      Cancel Request
                    </Button>
                  )}
                </div>
              )}
            </Card>

            {/* Department Info */}
            <Card style={{padding: '1.5rem'}}>
              <h3 style={{fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                <Building size={18} />
                Department
              </h3>
              <div style={{display: 'flex', flexDirection: 'column', gap: '0.75rem'}}>
                <div style={{fontWeight: '500', color: 'var(--text-primary)'}}>{requestData.department?.name}</div>
                {requestData.department?.office_address && (
                  <div style={{display: 'flex', alignItems: 'flex-start', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                    <FileText size={16} style={{flexShrink: 0, marginTop: '2px'}} />
                    <span>{requestData.department.office_address}</span>
                  </div>
                )}
              </div>
            </Card>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
};
