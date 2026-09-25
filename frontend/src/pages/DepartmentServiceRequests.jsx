import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { MapPin, Calendar, AlertCircle, RefreshCw, Filter, User, Package } from 'lucide-react';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const DepartmentServiceRequests = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState(searchParams.get('status') || 'ALL');
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 10,
    total: 0,
    totalPages: 0
  });

  const fetchRequests = async () => {
    setLoading(true);
    setError('');
    try {
      const params = new URLSearchParams();
      if (filter !== 'ALL') {
        params.append('status', filter);
      }
      params.append('page', pagination.page);
      params.append('limit', pagination.limit);
      
      const queryString = params.toString();
      const res = await api.get(`/departments/service-requests${queryString ? `?${queryString}` : ''}`);
      setRequests(res.requests || []);
      setPagination({
        page: res.page || 1,
        limit: res.limit || 10,
        total: res.total || 0,
        totalPages: res.totalPages || 0
      });
    } catch (err) {
      setError('Unable to load service requests.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRequests();
  }, [filter, pagination.page]);

  const handleFilterChange = (newFilter) => {
    setFilter(newFilter);
    setPagination(prev => ({ ...prev, page: 1 }));
    if (newFilter === 'ALL') {
      setSearchParams({});
    } else {
      setSearchParams({ status: newFilter });
    }
  };

  const handlePageChange = (newPage) => {
    setPagination(prev => ({ ...prev, page: newPage }));
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const getStatusBadge = (status) => {
    switch(status) {
      case 'PENDING': return <span style={{backgroundColor: 'var(--warning-100)', color: 'var(--warning-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>PENDING</span>;
      case 'ACCEPTED': return <span style={{backgroundColor: 'var(--info-100)', color: 'var(--info-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>ACCEPTED</span>;
      case 'IN_PROGRESS': return <span style={{backgroundColor: 'var(--primary-100)', color: 'var(--primary-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>IN PROGRESS</span>;
      case 'COMPLETED': return <span style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>COMPLETED</span>;
      case 'REJECTED': return <span style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>REJECTED</span>;
      case 'CANCELLED': return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>CANCELLED</span>;
      default: return <span style={{backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', padding: '0.25rem 0.5rem', borderRadius: '1rem', fontSize: '0.75rem', fontWeight: '600'}}>{status}</span>;
    }
  };

  return (
    <DepartmentDashboardLayout>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem'}}>
        <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
          Service Requests
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
            onChange={(e) => handleFilterChange(e.target.value)}
            className="input-field"
            style={{width: 'auto', minWidth: '200px', padding: '0.5rem 0.75rem'}}
          >
            <option value="ALL">All Requests</option>
            <option value="PENDING">Pending</option>
            <option value="ACCEPTED">Accepted</option>
            <option value="IN_PROGRESS">In Progress</option>
            <option value="COMPLETED">Completed</option>
            <option value="REJECTED">Rejected</option>
            <option value="CANCELLED">Cancelled</option>
          </select>
        </div>
      </Card>

      {error ? (
        <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Requests</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error}</p>
            </div>
            <Button variant="outline" onClick={fetchRequests} style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '1rem'}}>
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
      ) : requests.length === 0 ? (
        <Card style={{textAlign: 'center', padding: '4rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--text-secondary)'}}>
            <div style={{width: '64px', height: '64px', borderRadius: '50%', backgroundColor: 'var(--primary-50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-600)'}}>
              <Package size={32} />
            </div>
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>No requests found</h3>
              <p style={{margin: 0, maxWidth: '400px'}}>
                {filter === 'ALL' ? 'No service requests assigned to your department yet.' : `No requests with status: ${filter}`}
              </p>
            </div>
          </div>
        </Card>
      ) : (
        <>
          <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem', marginBottom: '2rem'}}>
            {requests.map(request => (
              <Card 
                key={request.id} 
                style={{
                  padding: '1.5rem', 
                  display: 'flex', 
                  flexDirection: 'column',
                  cursor: 'pointer',
                  transition: 'transform 0.2s, box-shadow 0.2s'
                }}
                onClick={() => navigate(`/department/service-requests/${request.id}`)}
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
                    {request.service?.name || 'Unknown Service'}
                  </h3>
                  {getStatusBadge(request.status)}
                </div>
                
                {request.service?.category && (
                  <div style={{fontSize: '0.875rem', color: 'var(--text-secondary)', marginBottom: '0.5rem'}}>
                    <strong>Category:</strong> {request.service.category}
                  </div>
                )}
                
                {request.notes && (
                  <div style={{fontSize: '0.875rem', color: 'var(--text-secondary)', marginBottom: '0.75rem', lineHeight: '1.5'}}>
                    {request.notes.length > 100 ? `${request.notes.substring(0, 100)}...` : request.notes}
                  </div>
                )}
                
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', color: 'var(--text-tertiary)', marginBottom: '0.5rem'}}>
                  <Calendar size={14} />
                  Submitted: {new Date(request.createdAt).toLocaleDateString()}
                </div>
                
                {request.citizen && (
                  <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.75rem', paddingTop: '0.75rem', borderTop: '1px solid var(--border-color)', fontSize: '0.875rem', color: 'var(--text-secondary)'}}>
                    <User size={14} />
                    Requested by: {request.citizen.name}
                  </div>
                )}
                
                <div style={{marginTop: 'auto', paddingTop: '1rem'}}>
                  <Button 
                    variant="primary" 
                    style={{width: '100%', fontSize: '0.875rem'}}
                    onClick={(e) => {
                      e.stopPropagation();
                      navigate(`/department/service-requests/${request.id}`);
                    }}
                  >
                    View Details
                  </Button>
                </div>
              </Card>
            ))}
          </div>

          {/* Pagination */}
          {pagination.totalPages > 1 && (
            <Card style={{padding: '1rem'}}>
              <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem', flexWrap: 'wrap'}}>
                <div style={{color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                  Showing {requests.length} of {pagination.total} requests
                </div>
                <div style={{display: 'flex', gap: '0.5rem'}}>
                  <Button
                    variant="outline"
                    onClick={() => handlePageChange(pagination.page - 1)}
                    disabled={pagination.page <= 1}
                    style={{fontSize: '0.875rem'}}
                  >
                    Previous
                  </Button>
                  <div style={{display: 'flex', alignItems: 'center', padding: '0 1rem', fontSize: '0.875rem', color: 'var(--text-secondary)'}}>
                    Page {pagination.page} of {pagination.totalPages}
                  </div>
                  <Button
                    variant="outline"
                    onClick={() => handlePageChange(pagination.page + 1)}
                    disabled={pagination.page >= pagination.totalPages}
                    style={{fontSize: '0.875rem'}}
                  >
                    Next
                  </Button>
                </div>
              </div>
            </Card>
          )}
        </>
      )}
    </DepartmentDashboardLayout>
  );
};
