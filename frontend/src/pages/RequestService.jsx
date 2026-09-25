import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, Building2 } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const RequestService = () => {
  const navigate = useNavigate();
  const location = useLocation();
  
  const searchParams = new URLSearchParams(location.search);
  const preselectedServiceId = searchParams.get('service_id') || '';

  const [formData, setFormData] = useState({
    service_id: preselectedServiceId,
    notes: ''
  });
  
  const [services, setServices] = useState([]);
  const [selectedService, setSelectedService] = useState(null);
  
  const [loadingData, setLoadingData] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      setLoadingData(true);
      setError('');
      try {
        const servicesRes = await api.get('/services');
        setServices(servicesRes.services || []);
        
        // If a service was preselected, find and set it
        if (preselectedServiceId) {
          const preselected = servicesRes.services.find(s => s.id === preselectedServiceId);
          if (preselected) {
            setSelectedService(preselected);
          }
        }
      } catch (err) {
        setError('Failed to load services. Please try again.');
      } finally {
        setLoadingData(false);
      }
    };

    fetchData();
  }, [preselectedServiceId]);

  const handleServiceChange = (e) => {
    const serviceId = e.target.value;
    setFormData(prev => ({ ...prev, service_id: serviceId }));
    
    // Find and set the selected service to show department info
    const service = services.find(s => s.id === serviceId);
    setSelectedService(service || null);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    
    if (!formData.service_id) {
      setError('Please select a service.');
      return;
    }

    setSubmitting(true);
    try {
      // Only send service_id and notes - backend will determine department
      await api.post('/services/requests', {
        service_id: formData.service_id,
        notes: formData.notes
      });
      navigate('/citizen/my-requests');
    } catch (err) {
      setError(err.message || 'Failed to submit service request. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <DashboardLayout>
      <div style={{maxWidth: '800px', margin: '0 auto'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem'}}>
          <button 
            onClick={() => navigate('/citizen/services')}
            style={{background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', color: 'var(--text-secondary)'}}
          >
            <ArrowLeft size={20} />
          </button>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
            Request Municipal Service
          </h1>
        </div>

        <Card>
          {error && (
            <div style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.75rem', borderRadius: 'var(--border-radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem'}}>
              {error}
            </div>
          )}

          {loadingData ? (
            <div style={{padding: '2rem', textAlign: 'center', color: 'var(--text-secondary)'}}>
              Loading services...
            </div>
          ) : (
            <form onSubmit={handleSubmit} style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
              
              <div className="input-group">
                <label className="input-label">Select Service <span style={{color: 'var(--danger-500)'}}>*</span></label>
                <select 
                  name="service_id"
                  value={formData.service_id}
                  onChange={handleServiceChange}
                  className="input-field"
                  required
                >
                  <option value="">-- Choose a service --</option>
                  {services.map(s => (
                    <option key={s.id} value={s.id}>
                      {s.name} ({s.category.replace(/_/g, ' ')})
                    </option>
                  ))}
                </select>
              </div>

              {selectedService && selectedService.department && (
                <div style={{
                  backgroundColor: 'var(--primary-50)', 
                  border: '1px solid var(--primary-200)',
                  borderRadius: 'var(--border-radius-md)',
                  padding: '1rem',
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: '0.75rem'
                }}>
                  <Building2 size={20} style={{color: 'var(--primary-600)', marginTop: '0.125rem', flexShrink: 0}} />
                  <div style={{flex: 1}}>
                    <div style={{fontSize: '0.75rem', color: 'var(--primary-700)', fontWeight: '600', marginBottom: '0.25rem'}}>
                      Responsible Department
                    </div>
                    <div style={{fontSize: '0.875rem', color: 'var(--primary-900)', fontWeight: '600', marginBottom: '0.25rem'}}>
                      {selectedService.department.name}
                    </div>
                    <div style={{fontSize: '0.75rem', color: 'var(--primary-700)'}}>
                      {selectedService.department.email}
                      {selectedService.department.mobile && ` • ${selectedService.department.mobile}`}
                    </div>
                  </div>
                </div>
              )}

              <div className="input-group">
                <label className="input-label">Additional Notes (Optional)</label>
                <textarea 
                  name="notes"
                  value={formData.notes}
                  onChange={handleInputChange}
                  className="input-field"
                  placeholder="Any specific details for this request..."
                  rows={4}
                  style={{resize: 'vertical'}}
                />
              </div>

              <div style={{display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '1rem'}}>
                <Button type="button" variant="secondary" onClick={() => navigate('/citizen/services')}>
                  Cancel
                </Button>
                <Button type="submit" variant="primary" disabled={submitting || !formData.service_id}>
                  {submitting ? 'Submitting...' : 'Submit Request'}
                </Button>
              </div>
            </form>
          )}
        </Card>
      </div>
    </DashboardLayout>
  );
};
