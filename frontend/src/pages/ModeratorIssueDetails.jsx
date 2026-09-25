import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Calendar, User, AlertCircle, CheckCircle, XCircle, RefreshCw, Building2 } from 'lucide-react';
import { ModeratorDashboardLayout } from '../layouts/ModeratorDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

// Add inline styles for animation
const spinKeyframes = `
@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
`;

export const ModeratorIssueDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [issue, setIssue] = useState(null);
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Separate state for approve and reject
  const [approving, setApproving] = useState(false);
  const [rejecting, setRejecting] = useState(false);
  const [selectedDepartment, setSelectedDepartment] = useState('');
  const [approveRemarks, setApproveRemarks] = useState('');
  const [rejectReason, setRejectReason] = useState('');
  const [actionError, setActionError] = useState('');
  const [actionSuccess, setActionSuccess] = useState('');

  useEffect(() => {
    fetchIssueDetails();
    fetchDepartments();
  }, [id]);

  const fetchIssueDetails = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get(`/issues/${id}`);
      setIssue(res.issue);
    } catch (err) {
      setError('Unable to load issue details.');
    } finally {
      setLoading(false);
    }
  };

  const fetchDepartments = async () => {
    try {
      const res = await api.get('/departments');
      setDepartments(res.departments || []);
    } catch (err) {
      console.error('Failed to load departments:', err);
    }
  };

  const handleApprove = async () => {
    if (!selectedDepartment) {
      setActionError('Please select a department to assign this issue.');
      return;
    }

    setApproving(true);
    setActionError('');
    setActionSuccess('');

    try {
      const payload = {
        decision: 'Approved',
        departmentId: selectedDepartment
      };

      if (approveRemarks.trim()) {
        payload.remarks = approveRemarks.trim();
      }

      await api.patch(`/issues/${id}/verify`, payload);
      
      setActionSuccess('Issue approved and assigned successfully!');
      setTimeout(() => {
        navigate('/moderator/issues');
      }, 1500);
    } catch (err) {
      setActionError(err.message || 'Failed to approve issue. Please try again.');
    } finally {
      setApproving(false);
    }
  };

  const handleReject = async () => {
    setRejecting(true);
    setActionError('');
    setActionSuccess('');

    try {
      const payload = {
        decision: 'Rejected'
      };

      if (rejectReason.trim()) {
        payload.remarks = rejectReason.trim();
      }

      await api.patch(`/issues/${id}/verify`, payload);
      
      setActionSuccess('Issue rejected successfully!');
      setTimeout(() => {
        navigate('/moderator/issues');
      }, 1500);
    } catch (err) {
      setActionError(err.message || 'Failed to reject issue. Please try again.');
    } finally {
      setRejecting(false);
    }
  };

  const handleVerify = async () => {
    if (decision === 'approve' && !selectedDepartment) {
      alert('Please select a department to assign this issue.');
      return;
    }

    setProcessing(true);
    try {
      const payload = {
        decision: decision === 'approve' ? 'Approved' : 'Rejected'
      };

      if (decision === 'approve') {
        payload.departmentId = selectedDepartment;
      }

      if (remarks.trim()) {
        payload.remarks = remarks.trim();
      }

      await api.patch(`/issues/${id}/verify`, payload);
      
      alert(`Issue ${decision === 'approve' ? 'approved and assigned' : 'rejected'} successfully!`);
      navigate('/moderator/issues');
    } catch (err) {
      alert(err.response?.data?.message || `Failed to ${decision} issue.`);
    } finally {
      setProcessing(false);
    }
  };

  const getStatusBadge = (status) => {
    switch(status) {
      case 'REPORTED': return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>REPORTED</span>;
      case 'ASSIGNED': return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>ASSIGNED</span>;
      case 'IN_PROGRESS': return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>IN PROGRESS</span>;
      case 'RESOLVED': return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>RESOLVED</span>;
      case 'REJECTED': return <span style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>REJECTED</span>;
      default: return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.375rem 0.75rem', borderRadius: '1rem', fontSize: '0.875rem', fontWeight: '600'}}>{status}</span>;
    }
  };

  if (loading) {
    return (
      <ModeratorDashboardLayout>
        <Card style={{padding: '3rem', textAlign: 'center'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--text-secondary)'}}>
            <RefreshCw size={32} className="animate-spin" />
            <p>Loading issue details...</p>
          </div>
        </Card>
      </ModeratorDashboardLayout>
    );
  }

  if (error || !issue) {
    return (
      <ModeratorDashboardLayout>
        <Card style={{padding: '3rem', textAlign: 'center'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Issue</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error || 'Issue not found'}</p>
            </div>
            <div style={{display: 'flex', gap: '1rem', marginTop: '1rem'}}>
              <Button variant="outline" onClick={() => navigate('/moderator/issues')} style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
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
      </ModeratorDashboardLayout>
    );
  }

  const canVerify = issue.status === 'REPORTED';

  return (
    <ModeratorDashboardLayout>
      <style>{spinKeyframes}</style>
      <div style={{marginBottom: '1.5rem'}}>
        <Button 
          variant="ghost" 
          onClick={() => navigate('/moderator/issues')}
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

      <div style={{display: 'grid', gridTemplateColumns: canVerify ? '1fr 400px' : '1fr', gap: '1.5rem'}}>
        {/* Issue Details */}
        <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
          <Card style={{padding: '1.5rem'}}>
            <h2 style={{margin: '0 0 1rem 0', fontSize: '1.25rem', fontWeight: '600', color: 'var(--text-primary)'}}>
              {issue.title}
            </h2>

            <div style={{display: 'grid', gap: '1rem', marginBottom: '1.5rem'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '100px', fontWeight: '600', color: 'var(--text-secondary)'}}>Category:</div>
                <div style={{color: 'var(--text-primary)'}}>{issue.category}</div>
              </div>

              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '100px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <MapPin size={14} />
                  Location:
                </div>
                <div style={{color: 'var(--text-primary)'}}>{issue.location}</div>
              </div>

              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '100px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <User size={14} />
                  Reported By:
                </div>
                <div style={{color: 'var(--text-primary)'}}>
                  {issue.reportedBy?.name || 'Unknown'} ({issue.reportedBy?.email || 'N/A'})
                </div>
              </div>

              <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                <div style={{width: '100px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <Calendar size={14} />
                  Reported On:
                </div>
                <div style={{color: 'var(--text-primary)'}}>
                  {new Date(issue.createdAt).toLocaleString()}
                </div>
              </div>

              {issue.department_id && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '0.875rem'}}>
                  <div style={{width: '100px', fontWeight: '600', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                    <Building2 size={14} />
                    Department:
                  </div>
                  <div style={{color: 'var(--text-primary)'}}>
                    {issue.department_id?.name || 'Unknown Department'}
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
          {issue.status === 'RESOLVED' && issue.resolution_details && (
            <Card style={{padding: '1.5rem', backgroundColor: 'var(--success-50)', borderColor: 'var(--success-200)'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem', color: 'var(--success-700)'}}>
                <CheckCircle size={20} />
                <h3 style={{margin: 0, fontSize: '1rem', fontWeight: '600'}}>Resolved</h3>
              </div>
              <p style={{margin: '0 0 0.5rem 0', color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                {issue.resolution_details}
              </p>
              {issue.resolution_evidence_url && (
                <img 
                  src={issue.resolution_evidence_url} 
                  alt="Resolution evidence" 
                  style={{
                    width: '100%', 
                    maxWidth: '400px',
                    height: 'auto',
                    borderRadius: '8px',
                    border: '1px solid var(--success-200)',
                    marginTop: '0.75rem'
                  }}
                />
              )}
            </Card>
          )}

          {/* Rejection Details */}
          {issue.status === 'REJECTED' && (
            <Card style={{padding: '1.5rem', backgroundColor: 'var(--danger-50)', borderColor: 'var(--danger-200)'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.75rem', color: 'var(--danger-700)'}}>
                <XCircle size={20} />
                <h3 style={{margin: 0, fontSize: '1rem', fontWeight: '600'}}>Rejected</h3>
              </div>
              {issue.remarks && (
                <p style={{margin: 0, color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  <strong>Reason:</strong> {issue.remarks}
                </p>
              )}
            </Card>
          )}
        </div>

        {/* Verification Panel */}
        {canVerify && (
          <div style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
            {/* Success/Error Messages */}
            {actionSuccess && (
              <div style={{
                padding: '1rem',
                backgroundColor: 'var(--success-100)',
                color: 'var(--success-700)',
                borderRadius: 'var(--border-radius-md)',
                border: '1px solid var(--success-600)',
                fontSize: '0.875rem',
                fontWeight: '500',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem'
              }}>
                <CheckCircle size={18} />
                {actionSuccess}
              </div>
            )}

            {actionError && (
              <div style={{
                padding: '1rem',
                backgroundColor: 'var(--danger-100)',
                color: 'var(--danger-700)',
                borderRadius: 'var(--border-radius-md)',
                border: '1px solid var(--danger-600)',
                fontSize: '0.875rem',
                fontWeight: '500',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem'
              }}>
                <AlertCircle size={18} />
                {actionError}
              </div>
            )}

            {/* Approve Section */}
            <Card style={{padding: '1.5rem'}}>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                marginBottom: '1.25rem',
                color: 'var(--success-700)'
              }}>
                <CheckCircle size={22} strokeWidth={2.5} />
                <h3 style={{margin: 0, fontSize: '1.125rem', fontWeight: '600'}}>
                  Approve Issue
                </h3>
              </div>

              <div style={{marginBottom: '1.25rem'}}>
                <label 
                  htmlFor="department" 
                  style={{
                    display: 'block',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    color: 'var(--text-primary)',
                    marginBottom: '0.5rem'
                  }}
                >
                  Assign to Department <span style={{color: 'var(--danger-600)'}}>*</span>
                </label>
                <select
                  id="department"
                  value={selectedDepartment}
                  onChange={(e) => {
                    setSelectedDepartment(e.target.value);
                    setActionError('');
                  }}
                  disabled={approving || rejecting}
                  style={{
                    width: '100%',
                    padding: '0.75rem',
                    fontSize: '0.875rem',
                    border: selectedDepartment ? '2px solid var(--success-600)' : '2px solid var(--border-color)',
                    borderRadius: 'var(--border-radius-md)',
                    backgroundColor: 'var(--bg-surface)',
                    color: 'var(--text-primary)',
                    cursor: 'pointer',
                    transition: 'all 0.2s ease',
                    outline: 'none'
                  }}
                  onFocus={(e) => {
                    if (!selectedDepartment) {
                      e.target.style.borderColor = 'var(--primary-500)';
                      e.target.style.boxShadow = '0 0 0 3px var(--primary-100)';
                    }
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = selectedDepartment ? 'var(--success-600)' : 'var(--border-color)';
                    e.target.style.boxShadow = 'none';
                  }}
                >
                  <option value="">Select a department...</option>
                  {departments.map(dept => (
                    <option key={dept._id || dept.id} value={dept._id || dept.id}>
                      {dept.name}
                    </option>
                  ))}
                </select>
                {!selectedDepartment && (
                  <p style={{
                    margin: '0.5rem 0 0 0',
                    fontSize: '0.75rem',
                    color: 'var(--text-secondary)',
                    fontStyle: 'italic'
                  }}>
                    Department selection is required to approve the issue
                  </p>
                )}
              </div>

              <div style={{marginBottom: '1.25rem'}}>
                <label 
                  htmlFor="approve-remarks" 
                  style={{
                    display: 'block',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    color: 'var(--text-primary)',
                    marginBottom: '0.5rem'
                  }}
                >
                  Additional Notes (Optional)
                </label>
                <textarea
                  id="approve-remarks"
                  rows={3}
                  placeholder="Add any notes or instructions for the department..."
                  value={approveRemarks}
                  onChange={(e) => setApproveRemarks(e.target.value)}
                  disabled={approving || rejecting}
                  style={{
                    width: '100%',
                    padding: '0.75rem',
                    fontSize: '0.875rem',
                    border: '1px solid var(--border-color)',
                    borderRadius: 'var(--border-radius-md)',
                    backgroundColor: 'var(--bg-surface)',
                    color: 'var(--text-primary)',
                    resize: 'vertical',
                    fontFamily: 'inherit',
                    lineHeight: '1.5',
                    transition: 'border-color 0.2s ease',
                    outline: 'none'
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = 'var(--primary-500)';
                    e.target.style.boxShadow = '0 0 0 3px var(--primary-100)';
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = 'var(--border-color)';
                    e.target.style.boxShadow = 'none';
                  }}
                />
              </div>

              <button
                onClick={handleApprove}
                disabled={!selectedDepartment || approving || rejecting}
                style={{
                  width: '100%',
                  height: '48px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  backgroundColor: selectedDepartment && !approving && !rejecting ? 'var(--success-600)' : 'var(--secondary-200)',
                  color: selectedDepartment && !approving && !rejecting ? 'white' : 'var(--text-secondary)',
                  border: 'none',
                  borderRadius: 'var(--border-radius-md)',
                  fontSize: '1rem',
                  fontWeight: '600',
                  cursor: selectedDepartment && !approving && !rejecting ? 'pointer' : 'not-allowed',
                  transition: 'all 0.2s ease',
                  boxShadow: selectedDepartment && !approving && !rejecting ? '0 2px 8px rgba(22, 163, 74, 0.25)' : 'none',
                  outline: 'none'
                }}
                onMouseEnter={(e) => {
                  if (selectedDepartment && !approving && !rejecting) {
                    e.target.style.backgroundColor = 'var(--success-700)';
                    e.target.style.transform = 'translateY(-1px)';
                    e.target.style.boxShadow = '0 4px 12px rgba(22, 163, 74, 0.3)';
                  }
                }}
                onMouseLeave={(e) => {
                  if (selectedDepartment && !approving && !rejecting) {
                    e.target.style.backgroundColor = 'var(--success-600)';
                    e.target.style.transform = 'translateY(0)';
                    e.target.style.boxShadow = '0 2px 8px rgba(22, 163, 74, 0.25)';
                  }
                }}
                onFocus={(e) => {
                  if (selectedDepartment && !approving && !rejecting) {
                    e.target.style.boxShadow = '0 0 0 4px var(--success-100), 0 2px 8px rgba(22, 163, 74, 0.25)';
                  }
                }}
                onBlur={(e) => {
                  if (selectedDepartment && !approving && !rejecting) {
                    e.target.style.boxShadow = '0 2px 8px rgba(22, 163, 74, 0.25)';
                  }
                }}
              >
                {approving ? (
                  <>
                    <RefreshCw size={20} style={{animation: 'spin 1s linear infinite'}} />
                    Approving...
                  </>
                ) : (
                  <>
                    <CheckCircle size={20} />
                    Approve & Assign
                  </>
                )}
              </button>
            </Card>

            {/* Reject Section */}
            <Card style={{padding: '1.5rem'}}>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                marginBottom: '1.25rem',
                color: 'var(--danger-700)'
              }}>
                <XCircle size={22} strokeWidth={2.5} />
                <h3 style={{margin: 0, fontSize: '1.125rem', fontWeight: '600'}}>
                  Reject Issue
                </h3>
              </div>

              <div style={{marginBottom: '1.25rem'}}>
                <label 
                  htmlFor="reject-reason" 
                  style={{
                    display: 'block',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    color: 'var(--text-primary)',
                    marginBottom: '0.5rem'
                  }}
                >
                  Reason for Rejection (Optional)
                </label>
                <textarea
                  id="reject-reason"
                  rows={4}
                  placeholder="Explain why this issue is being rejected..."
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  disabled={approving || rejecting}
                  style={{
                    width: '100%',
                    padding: '0.75rem',
                    fontSize: '0.875rem',
                    border: '1px solid var(--border-color)',
                    borderRadius: 'var(--border-radius-md)',
                    backgroundColor: 'var(--bg-surface)',
                    color: 'var(--text-primary)',
                    resize: 'vertical',
                    fontFamily: 'inherit',
                    lineHeight: '1.5',
                    transition: 'border-color 0.2s ease',
                    outline: 'none'
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = 'var(--primary-500)';
                    e.target.style.boxShadow = '0 0 0 3px var(--primary-100)';
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = 'var(--border-color)';
                    e.target.style.boxShadow = 'none';
                  }}
                />
              </div>

              <button
                onClick={handleReject}
                disabled={approving || rejecting}
                style={{
                  width: '100%',
                  height: '48px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  backgroundColor: !approving && !rejecting ? 'var(--danger-600)' : 'var(--secondary-200)',
                  color: !approving && !rejecting ? 'white' : 'var(--text-secondary)',
                  border: 'none',
                  borderRadius: 'var(--border-radius-md)',
                  fontSize: '1rem',
                  fontWeight: '600',
                  cursor: !approving && !rejecting ? 'pointer' : 'not-allowed',
                  transition: 'all 0.2s ease',
                  boxShadow: !approving && !rejecting ? '0 2px 8px rgba(220, 38, 38, 0.25)' : 'none',
                  outline: 'none'
                }}
                onMouseEnter={(e) => {
                  if (!approving && !rejecting) {
                    e.target.style.backgroundColor = 'var(--danger-700)';
                    e.target.style.transform = 'translateY(-1px)';
                    e.target.style.boxShadow = '0 4px 12px rgba(220, 38, 38, 0.3)';
                  }
                }}
                onMouseLeave={(e) => {
                  if (!approving && !rejecting) {
                    e.target.style.backgroundColor = 'var(--danger-600)';
                    e.target.style.transform = 'translateY(0)';
                    e.target.style.boxShadow = '0 2px 8px rgba(220, 38, 38, 0.25)';
                  }
                }}
                onFocus={(e) => {
                  if (!approving && !rejecting) {
                    e.target.style.boxShadow = '0 0 0 4px var(--danger-100), 0 2px 8px rgba(220, 38, 38, 0.25)';
                  }
                }}
                onBlur={(e) => {
                  if (!approving && !rejecting) {
                    e.target.style.boxShadow = '0 2px 8px rgba(220, 38, 38, 0.25)';
                  }
                }}
              >
                {rejecting ? (
                  <>
                    <RefreshCw size={20} style={{animation: 'spin 1s linear infinite'}} />
                    Rejecting...
                  </>
                ) : (
                  <>
                    <XCircle size={20} />
                    Reject Issue
                  </>
                )}
              </button>
            </Card>
          </div>
        )}
      </div>
    </ModeratorDashboardLayout>
  );
};
