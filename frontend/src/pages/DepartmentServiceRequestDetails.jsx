import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Calendar, User, AlertCircle, CheckCircle, RefreshCw, Building2, Play, XCircle, Package, FileText, Star, MessageSquare } from 'lucide-react';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const DepartmentServiceRequestDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [request, setRequest] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [processing, setProcessing] = useState(false);
  
  // Feedback state
  const [feedbackData, setFeedbackData] = useState(null);
  
  // Reject form state
  const [showRejectForm, setShowRejectForm] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');

  useEffect(() => {
    fetchRequestDetails();
  }, [id]);

  const fetchRequestDetails = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get(`/services/requests/${id}`);
      setRequest(res.serviceRequest);
      
      // If completed, try to fetch feedback
      if (res.serviceRequest.status === 'COMPLETED') {
        try {
          const feedbackRes = await api.get(`/services/requests/${id}/feedback`);
          setFeedbackData(feedbackRes.feedback);
        } catch (err) {
          // If 404, no feedback exists yet - this is fine
          if (err.status !== 404) {
            console.error("Error fetching feedback", err);
          }
        }
      }
    } catch (err) {
      setError('Unable to load request details.');
    } finally {
      setLoading(false);
    }
  };

  const handleAccept = async () => {
    if (!window.confirm('Are you sure you want to accept this service request?')) {
      return;
    }

    setProcessing(true);
    try {
      const res = await api.patch(`/services/requests/${id}/accept`);
      setRequest(res.serviceRequest);
      alert('Service request accepted successfully!');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to accept request.');
    } finally {
      setProcessing(false);
    }
  };

  const handleReject = async (e) => {
    e.preventDefault();

    if (!rejectionReason.trim()) {
      alert('Please provide a rejection reason.');
      return;
    }

    setProcessing(true);
    try {
      const res = await api.patch(`/services/requests/${id}/reject`, {
        rejectionReason: rejectionReason.trim()
      });
      setRequest(res.serviceRequest);
      setShowRejectForm(false);
      setRejectionReason('');
      alert('Service request rejected.');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to reject request.');
    } finally {
      setProcessing(false);
    }
  };

  const handleStart = async () => {
    if (!window.confirm('Are you sure you want to start work on this service request?')) {
      return;
    }

    setProcessing(true);
    try {
      const res = await api.patch(`/services/requests/${id}/start`);
      setRequest(res.serviceRequest);
      alert('Service request moved to IN PROGRESS!');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to start request.');
    } finally {
      setProcessing(false);
    }
  };

  const handleComplete = async () => {
    if (!window.confirm('Are you sure you want to mark this service request as completed?')) {
      return;
    }

    setProcessing(true);
    try {
      const res = await api.patch(`/services/requests/${id}/complete`);
      setRequest(res.serviceRequest);
      alert('Service request completed successfully!');
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to complete request.');
    } finally {
      setProcessing(false);
    }
  };

  const getStatusBadge = (status) => {
    switch(status) {
      case 'PENDING': return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>PENDING</span>;
      case 'ACCEPTED': return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>ACCEPTED</span>;
      case 'IN_PROGRESS': return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>IN PROGRESS</span>;
      case 'COMPLETED': return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>COMPLETED</span>;
      case 'REJECTED': return <span style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>REJECTED</span>;
      case 'CANCELLED': return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>CANCELLED</span>;
      default: return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>{status}</span>;
    }
  };

  if (loading) {
    return (
      <DepartmentDashboardLayout>
        <Card style={{padding: '3rem', textAlign: 'center'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--text-secondary)'}}>
            <RefreshCw size={32} className="animate-spin" />
            <p>Loading request details...</p>
          </div>
        </Card>
      </DepartmentDashboardLayout>
    );
  }

  if (error || !request) {
    return (
      <DepartmentDashboardLayout>
        <Card style={{padding: '3rem', textAlign: 'center'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Request</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error || 'Request not found'}</p>
            </div>
            <div style={{display: 'flex', gap: '1rem', marginTop: '1rem'}}>
              <Button variant="outline" onClick={() => navigate('/department/service-requests')} style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                <ArrowLeft size={16} />
                Back to Requests
              </Button>
              <Button variant="outline" onClick={fetchRequestDetails} style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                <RefreshCw size={16} />
                Retry
              </Button>
            </div>
          </div>
        </Card>
      </DepartmentDashboardLayout>
    );
  }

  const canAcceptOrReject = request.status === 'PENDING';
  const canStart = request.status === 'ACCEPTED';
  const canComplete = request.status === 'IN_PROGRESS';
  const isCompleted = request.status === 'COMPLETED';
  const isRejected = request.status === 'REJECTED';
  const isCancelled = request.status === 'CANCELLED';

  return (
    <DepartmentDashboardLayout>
      <div style={{marginBottom: '1.5rem'}}>
        <Button 
          variant="ghost" 
          onClick={() => navigate('/department/service-requests')}
          style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem'}}
        >
          <ArrowLeft size={16} />
          Back to Service Requests
        </Button>
        
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '1rem', flexWrap: 'wrap'}}>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
            Service Request Details
          </h1>
          {getStatusBadge(request.status)}
        </div>
      </div>

      <div style={{display: 'grid', gridTemplateColumns: showRejectForm ? '1fr 400px' : '1fr', gap: '1.5rem'}}>
        {/* Request Details */}
        <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
          <Card style={{padding: '1.5rem'}}>
            <h2 style={{margin: '0 0 1rem 0', fontSize: '1.25rem', fontWeight: '600', color: 'var(--text-primary)'}}>
              {request.service?.name || 'Unknown Service'}
            </h2>

            <div style={{display: 'grid', gap: '1rem', marginBottom: '1.5rem'}}>
              {request.service?.category && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)'}}>Category:</div>
                  <div style={{color: 'var(--text-primary)'}}>{request.service.category}</div>
                </div>
              )}

              {request.service?.description && (
                <div style={{display: 'flex', alignItems: 'flex-start', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)'}}>Service:</div>
                  <div style={{color: 'var(--text-primary)', flex: 1}}>{request.service.description}</div>
                </div>
              )}

              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <User size={14} />
                  Requested By:
                </div>
                <div style={{color: 'var(--text-primary)'}}>
                  {request.citizen?.name || 'Unknown'} {request.citizen?.email && `(${request.citizen.email})`}
                </div>
              </div>

              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <Calendar size={14} />
                  Submitted On:
                </div>
                <div style={{color: 'var(--text-primary)'}}>
                  {new Date(request.createdAt).toLocaleString()}
                </div>
              </div>

              {request.department && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                    <Building2 size={14} />
                    Department:
                  </div>
                  <div style={{color: 'var(--text-primary)'}}>
                    {request.department.name}
                  </div>
                </div>
              )}

              {request.acceptedAt && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)'}}>Accepted On:</div>
                  <div style={{color: 'var(--text-primary)'}}>
                    {new Date(request.acceptedAt).toLocaleString()}
                  </div>
                </div>
              )}

              {request.startedAt && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)'}}>Started On:</div>
                  <div style={{color: 'var(--text-primary)'}}>
                    {new Date(request.startedAt).toLocaleString()}
                  </div>
                </div>
              )}

              {request.completedAt && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)'}}>Completed On:</div>
                  <div style={{color: 'var(--text-primary)'}}>
                    {new Date(request.completedAt).toLocaleString()}
                  </div>
                </div>
              )}

              {request.rejectedAt && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)'}}>Rejected On:</div>
                  <div style={{color: 'var(--text-primary)'}}>
                    {new Date(request.rejectedAt).toLocaleString()}
                  </div>
                </div>
              )}

              {request.cancelledAt && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '120px', fontWeight: '600', color: 'var(--text-secondary)'}}>Cancelled On:</div>
                  <div style={{color: 'var(--text-primary)'}}>
                    {new Date(request.cancelledAt).toLocaleString()}
                  </div>
                </div>
              )}
            </div>

            {request.notes && (
              <div style={{marginBottom: '1.5rem'}}>
                <h3 style={{margin: '0 0 0.5rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <FileText size={18} />
                  Request Notes
                </h3>
                <p style={{margin: 0, color: 'var(--text-secondary)', lineHeight: '1.6', padding: '1rem', backgroundColor: 'var(--bg-secondary)', borderRadius: 'var(--border-radius-md)'}}>
                  {request.notes}
                </p>
              </div>
            )}
          </Card>

          {/* Rejection Reason (if rejected) */}
          {isRejected && request.rejectionReason && (
            <Card style={{padding: '1.5rem', backgroundColor: 'var(--danger-50)', borderColor: 'var(--danger-200)'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem', color: 'var(--danger-700)'}}>
                <XCircle size={20} />
                <h3 style={{margin: 0, fontSize: '1rem', fontWeight: '600'}}>Rejected</h3>
              </div>
              <p style={{margin: 0, color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                <strong>Rejection Reason:</strong><br />
                {request.rejectionReason}
              </p>
            </Card>
          )}

          {/* Cancelled Notice */}
          {isCancelled && (
            <Card style={{padding: '1.5rem', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)'}}>
                <AlertCircle size={20} />
                <h3 style={{margin: 0, fontSize: '1rem', fontWeight: '600'}}>Request Cancelled by Citizen</h3>
              </div>
            </Card>
          )}

          {/* Citizen Feedback - Display only for COMPLETED requests */}
          {isCompleted && feedbackData && (
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

          {isCompleted && !feedbackData && (
            <Card style={{padding: '1.5rem', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                <Star size={18} />
                <span>No citizen feedback yet</span>
              </div>
            </Card>
          )}

          {/* Action Buttons */}
          {!isCompleted && !isRejected && !isCancelled && (
            <Card style={{padding: '1.5rem'}}>
              <h3 style={{margin: '0 0 1rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--text-primary)'}}>
                Actions
              </h3>
              <div style={{display: 'flex', gap: '1rem', flexWrap: 'wrap'}}>
                {canAcceptOrReject && (
                  <>
                    <Button
                      variant="primary"
                      onClick={handleAccept}
                      disabled={processing}
                      style={{display: 'flex', alignItems: 'center', gap: '0.5rem', backgroundColor: 'var(--success-600)'}}
                    >
                      {processing ? (
                        <>
                          <RefreshCw size={16} className="animate-spin" />
                          Processing...
                        </>
                      ) : (
                        <>
                          <CheckCircle size={16} />
                          Accept Request
                        </>
                      )}
                    </Button>

                    {!showRejectForm && (
                      <Button
                        variant="secondary"
                        onClick={() => setShowRejectForm(true)}
                        disabled={processing}
                        style={{display: 'flex', alignItems: 'center', gap: '0.5rem', backgroundColor: 'var(--danger-600)', color: 'white'}}
                      >
                        <XCircle size={16} />
                        Reject Request
                      </Button>
                    )}

                    {showRejectForm && (
                      <Button
                        variant="outline"
                        onClick={() => {
                          setShowRejectForm(false);
                          setRejectionReason('');
                        }}
                      >
                        Cancel Rejection
                      </Button>
                    )}
                  </>
                )}

                {canStart && (
                  <Button
                    variant="primary"
                    onClick={handleStart}
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

                {canComplete && (
                  <Button
                    variant="primary"
                    onClick={handleComplete}
                    disabled={processing}
                    style={{display: 'flex', alignItems: 'center', gap: '0.5rem', backgroundColor: 'var(--success-600)'}}
                  >
                    {processing ? (
                      <>
                        <RefreshCw size={16} className="animate-spin" />
                        Completing...
                      </>
                    ) : (
                      <>
                        <CheckCircle size={16} />
                        Complete Request
                      </>
                    )}
                  </Button>
                )}
              </div>
            </Card>
          )}
        </div>

        {/* Reject Form */}
        {showRejectForm && (
          <Card style={{padding: '1.5rem', height: 'fit-content'}}>
            <h3 style={{margin: '0 0 1rem 0', fontSize: '1rem', fontWeight: '600', color: 'var(--danger-600)'}}>
              Reject Service Request
            </h3>

            <form onSubmit={handleReject}>
              <div style={{marginBottom: '1.5rem'}}>
                <label htmlFor="rejection" className="form-label">
                  Rejection Reason <span style={{color: 'var(--danger-600)'}}>*</span>
                </label>
                <textarea
                  id="rejection"
                  className="input-field"
                  rows={5}
                  placeholder="Explain why this request is being rejected..."
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                  disabled={processing}
                  required
                />
              </div>

              <Button
                type="submit"
                variant="primary"
                disabled={processing || !rejectionReason.trim()}
                style={{width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', backgroundColor: 'var(--danger-600)'}}
              >
                {processing ? (
                  <>
                    <RefreshCw size={16} className="animate-spin" />
                    Rejecting...
                  </>
                ) : (
                  <>
                    <XCircle size={16} />
                    Submit Rejection
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
