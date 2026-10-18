import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Send, Save, AlertCircle } from 'lucide-react';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';

export const DepartmentCreateNotice = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    category: 'GENERAL',
    startDate: '',
    endDate: ''
  });
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);

  const categories = [
    { value: 'GENERAL', label: 'General' },
    { value: 'EMERGENCY', label: 'Emergency' },
    { value: 'MAINTENANCE', label: 'Maintenance' },
    { value: 'EVENT', label: 'Event' },
    { value: 'POLICY', label: 'Policy' },
    { value: 'ANNOUNCEMENT', label: 'Announcement' },
    { value: 'OTHER', label: 'Other' }
  ];

  const validate = () => {
    const newErrors = {};
    
    if (!formData.title.trim()) {
      newErrors.title = 'Title is required';
    } else if (formData.title.trim().length < 5) {
      newErrors.title = 'Title must be at least 5 characters';
    }
    
    if (!formData.content.trim()) {
      newErrors.content = 'Content is required';
    } else if (formData.content.trim().length < 10) {
      newErrors.content = 'Content must be at least 10 characters';
    }
    
    if (formData.startDate && formData.endDate) {
      if (new Date(formData.endDate) < new Date(formData.startDate)) {
        newErrors.endDate = 'End date cannot be earlier than start date';
      }
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (shouldPublish = false) => {
    if (!validate()) return;
    
    setSubmitting(true);
    try {
      const payload = {
        title: formData.title.trim(),
        content: formData.content.trim(),
        category: formData.category
      };
      
      if (formData.startDate) payload.startDate = formData.startDate;
      if (formData.endDate) payload.endDate = formData.endDate;
      
      const res = await api.post('/notices', payload);
      
      if (shouldPublish && res.notice) {
        await api.patch(`/notices/${res.notice.id}/publish`);
        alert('Notice published successfully! All citizens have been notified.');
      } else {
        alert('Notice saved as draft successfully!');
      }
      
      navigate('/department/notices');
    } catch (error) {
      alert(error.message || 'Failed to create notice');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <DepartmentDashboardLayout>
      <div style={{maxWidth: '800px', margin: '0 auto'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem'}}>
          <button 
            onClick={() => navigate('/department/notices')}
            style={{background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', color: 'var(--text-secondary)'}}
          >
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: '0 0 0.25rem 0'}}>
              Create Public Notice
            </h1>
            <p style={{margin: 0, color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
              Create a notice to inform citizens about important updates
            </p>
          </div>
        </div>

        <Card style={{padding: '1.5rem', marginBottom: '1rem'}}>
          <div style={{marginBottom: '1.5rem'}}>
            <label style={{display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: '500', color: 'var(--text-primary)'}}>
              Department
            </label>
            <div style={{padding: '0.75rem', backgroundColor: 'var(--bg-secondary)', borderRadius: 'var(--border-radius-md)', fontSize: '0.875rem', color: 'var(--text-secondary)'}}>
              {user?.name} (This notice will be posted by your department)
            </div>
          </div>

          <div style={{marginBottom: '1.5rem'}}>
            <label htmlFor="title" style={{display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: '500', color: 'var(--text-primary)'}}>
              Title <span style={{color: 'var(--danger-600)'}}>*</span>
            </label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({...formData, title: e.target.value})}
              placeholder="Enter notice title"
              style={{width: '100%'}}
            />
            {errors.title && (
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.5rem', color: 'var(--danger-600)', fontSize: '0.75rem'}}>
                <AlertCircle size={14} />
                {errors.title}
              </div>
            )}
          </div>

          <div style={{marginBottom: '1.5rem'}}>
            <label htmlFor="category" style={{display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: '500', color: 'var(--text-primary)'}}>
              Category <span style={{color: 'var(--danger-600)'}}>*</span>
            </label>
            <select
              id="category"
              value={formData.category}
              onChange={(e) => setFormData({...formData, category: e.target.value})}
              style={{
                width: '100%',
                padding: '0.75rem',
                border: '1px solid var(--border-color)',
                borderRadius: 'var(--border-radius-md)',
                fontSize: '0.875rem',
                backgroundColor: 'var(--bg-surface)',
                color: 'var(--text-primary)'
              }}
            >
              {categories.map(cat => (
                <option key={cat.value} value={cat.value}>{cat.label}</option>
              ))}
            </select>
          </div>

          <div style={{marginBottom: '1.5rem'}}>
            <label htmlFor="content" style={{display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: '500', color: 'var(--text-primary)'}}>
              Content <span style={{color: 'var(--danger-600)'}}>*</span>
            </label>
            <textarea
              id="content"
              value={formData.content}
              onChange={(e) => setFormData({...formData, content: e.target.value})}
              placeholder="Enter notice content"
              rows={8}
              style={{
                width: '100%',
                padding: '0.75rem',
                border: '1px solid var(--border-color)',
                borderRadius: 'var(--border-radius-md)',
                fontSize: '0.875rem',
                fontFamily: 'inherit',
                backgroundColor: 'var(--bg-surface)',
                color: 'var(--text-primary)',
                resize: 'vertical'
              }}
            />
            {errors.content && (
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.5rem', color: 'var(--danger-600)', fontSize: '0.75rem'}}>
                <AlertCircle size={14} />
                {errors.content}
              </div>
            )}
          </div>

          <div style={{display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem', marginBottom: '1.5rem'}}>
            <div>
              <label htmlFor="startDate" style={{display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: '500', color: 'var(--text-primary)'}}>
                Start Date (Optional)
              </label>
              <Input
                type="date"
                id="startDate"
                value={formData.startDate}
                onChange={(e) => setFormData({...formData, startDate: e.target.value})}
                style={{width: '100%'}}
              />
            </div>

            <div>
              <label htmlFor="endDate" style={{display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: '500', color: 'var(--text-primary)'}}>
                End Date (Optional)
              </label>
              <Input
                type="date"
                id="endDate"
                value={formData.endDate}
                onChange={(e) => setFormData({...formData, endDate: e.target.value})}
                style={{width: '100%'}}
              />
              {errors.endDate && (
                <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.5rem', color: 'var(--danger-600)', fontSize: '0.75rem'}}>
                  <AlertCircle size={14} />
                  {errors.endDate}
                </div>
              )}
            </div>
          </div>

          <div style={{display: 'flex', gap: '1rem', justifyContent: 'flex-end', paddingTop: '1rem', borderTop: '1px solid var(--border-color)'}}>
            <Button 
              variant="outline" 
              onClick={() => navigate('/department/notices')}
              disabled={submitting}
            >
              Cancel
            </Button>
            <Button 
              variant="secondary"
              onClick={() => handleSubmit(false)}
              disabled={submitting}
              style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}
            >
              <Save size={16} />
              Save as Draft
            </Button>
            <Button 
              variant="primary"
              onClick={() => handleSubmit(true)}
              disabled={submitting}
              style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}
            >
              <Send size={16} />
              Publish Now
            </Button>
          </div>
        </Card>
      </div>
    </DepartmentDashboardLayout>
  );
};
