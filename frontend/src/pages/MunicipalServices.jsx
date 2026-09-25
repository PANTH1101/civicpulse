import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { FileText, AlertCircle, ArrowRight, RefreshCw, Briefcase, Building2 } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const MunicipalServices = () => {
  const navigate = useNavigate();
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchServices = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/services');
      setServices(res.services || []);
    } catch (err) {
      setError('Unable to load municipal services.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchServices();
  }, []);

  return (
    <DashboardLayout>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem'}}>
        <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
          Browse Municipal Services
        </h1>
      </div>

      {error ? (
        <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
            <AlertCircle size={40} />
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Services</h3>
              <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error}</p>
            </div>
            <Button variant="outline" onClick={fetchServices} style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '1rem'}}>
              <RefreshCw size={16} />
              Retry
            </Button>
          </div>
        </Card>
      ) : loading ? (
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem'}}>
          {[1, 2, 3, 4, 5, 6].map(i => (
            <Card key={i} style={{padding: '1.5rem'}}>
              <div style={{height: '24px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '70%', marginBottom: '1rem'}} />
              <div style={{height: '16px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '40%', marginBottom: '0.5rem'}} />
              <div style={{height: '60px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '100%', marginBottom: '1.5rem'}} />
              <div style={{height: '32px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '100%'}} />
            </Card>
          ))}
        </div>
      ) : services.length === 0 ? (
        <Card style={{textAlign: 'center', padding: '4rem 1rem'}}>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--text-secondary)'}}>
            <div style={{width: '64px', height: '64px', borderRadius: '50%', backgroundColor: 'var(--primary-50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-600)'}}>
              <Briefcase size={32} />
            </div>
            <div>
              <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>No services available.</h3>
              <p style={{margin: 0, maxWidth: '400px'}}>There are currently no municipal services available.</p>
            </div>
          </div>
        </Card>
      ) : (
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem'}}>
          {services.map(service => (
            <Card key={service.id} style={{padding: '1.5rem', display: 'flex', flexDirection: 'column'}}>
              <div style={{marginBottom: '1rem'}}>
                <div style={{display: 'inline-block', backgroundColor: 'var(--bg-secondary)', padding: '0.25rem 0.5rem', borderRadius: '4px', fontSize: '0.75rem', fontWeight: '600', color: 'var(--text-secondary)', marginBottom: '0.5rem'}}>
                  {service.category.replace(/_/g, ' ')}
                </div>
                <h3 style={{margin: '0 0 0.5rem 0', fontSize: '1.125rem', fontWeight: '600', color: 'var(--text-primary)'}}>
                  {service.name}
                </h3>
              </div>
              
              <div style={{color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '1rem', flexGrow: 1, lineHeight: 1.5}}>
                {service.description}
              </div>
              
              {service.department && (
                <div style={{
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '0.5rem', 
                  padding: '0.75rem',
                  backgroundColor: 'var(--bg-secondary)',
                  borderRadius: 'var(--border-radius-md)',
                  marginBottom: '1rem',
                  fontSize: '0.75rem'
                }}>
                  <Building2 size={14} style={{color: 'var(--primary-600)', flexShrink: 0}} />
                  <span style={{color: 'var(--text-secondary)'}}>
                    {service.department.name}
                  </span>
                </div>
              )}
              
              <div style={{marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid var(--border-color)'}}>
                <Button 
                  variant="primary" 
                  style={{width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem'}}
                  onClick={() => navigate(`/citizen/services/request?service_id=${service.id}`)}
                >
                  Request Service
                  <ArrowRight size={16} />
                </Button>
              </div>
            </Card>
          ))}
        </div>
      )}
    </DashboardLayout>
  );
};
