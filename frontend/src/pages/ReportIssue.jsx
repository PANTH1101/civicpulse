import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Upload, ArrowLeft } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { api } from '../services/api';

const CATEGORIES = [
  "ROADS",
  "WATER",
  "ELECTRICITY",
  "SANITATION",
  "PUBLIC_SAFETY",
  "HEALTHCARE",
  "EDUCATION",
  "ENVIRONMENT",
  "OTHER"
];

export const ReportIssue = () => {
  const navigate = useNavigate();
  
  const [formData, setFormData] = useState({
    title: '',
    category: '',
    location: '',
    description: ''
  });
  const [image, setImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        setError('Image must be less than 5MB');
        return;
      }
      setImage(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    
    if (!formData.title || !formData.category || !formData.location || !formData.description) {
      setError('Please fill in all required fields');
      return;
    }

    setLoading(true);
    try {
      const payload = new FormData();
      payload.append('title', formData.title);
      payload.append('category', formData.category);
      payload.append('location', formData.location);
      payload.append('description', formData.description);
      
      if (image) {
        payload.append('image', image);
      }

      await api.post('/issues', payload);
      navigate('/citizen/my-issues');
    } catch (err) {
      setError(err.message || 'Failed to report civic issue. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <DashboardLayout>
      <div style={{maxWidth: '800px', margin: '0 auto'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem'}}>
          <button 
            onClick={() => navigate('/citizen/dashboard')}
            style={{background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', color: 'var(--text-secondary)'}}
          >
            <ArrowLeft size={20} />
          </button>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
            Report a Civic Issue
          </h1>
        </div>

        <Card>
          {error && (
            <div style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.75rem', borderRadius: 'var(--border-radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem'}}>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} style={{display: 'flex', flexDirection: 'column', gap: '1.5rem'}}>
            <Input 
              label="Issue Title" 
              name="title"
              value={formData.title}
              onChange={handleInputChange}
              placeholder="E.g. Broken street light on Main St."
              required
            />

            <div className="input-group">
              <label className="input-label">Category <span style={{color: 'var(--danger-500)'}}>*</span></label>
              <select 
                name="category"
                value={formData.category}
                onChange={handleInputChange}
                className="input-field"
                required
              >
                <option value="">Select a category</option>
                {CATEGORIES.map(cat => (
                  <option key={cat} value={cat}>
                    {cat.replace('_', ' ')}
                  </option>
                ))}
              </select>
            </div>

            <Input 
              label="Location" 
              name="location"
              value={formData.location}
              onChange={handleInputChange}
              placeholder="Exact address or landmark"
              required
            />

            <div className="input-group">
              <label className="input-label">Description <span style={{color: 'var(--danger-500)'}}>*</span></label>
              <textarea 
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                className="input-field"
                placeholder="Describe the issue in detail..."
                rows={5}
                required
                style={{resize: 'vertical'}}
              />
            </div>

            <div className="input-group">
              <label className="input-label">Photo Evidence (Optional)</label>
              <div 
                style={{
                  border: '2px dashed var(--border-color)', 
                  borderRadius: 'var(--border-radius-md)', 
                  padding: '2rem', 
                  textAlign: 'center',
                  backgroundColor: 'var(--bg-secondary)',
                  cursor: 'pointer',
                  position: 'relative'
                }}
                onClick={() => document.getElementById('imageUpload').click()}
              >
                {imagePreview ? (
                  <img src={imagePreview} alt="Preview" style={{maxHeight: '200px', maxWidth: '100%', objectFit: 'contain'}} />
                ) : (
                  <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)'}}>
                    <Upload size={32} />
                    <p>Click to upload an image</p>
                    <p style={{fontSize: '0.75rem'}}>PNG, JPG up to 5MB</p>
                  </div>
                )}
                <input 
                  id="imageUpload"
                  type="file" 
                  accept="image/*"
                  onChange={handleImageChange}
                  style={{display: 'none'}}
                />
              </div>
            </div>

            <div style={{display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '1rem'}}>
              <Button type="button" variant="secondary" onClick={() => navigate('/citizen/dashboard')}>
                Cancel
              </Button>
              <Button type="submit" variant="primary" disabled={loading}>
                {loading ? 'Submitting...' : 'Submit Issue'}
              </Button>
            </div>
          </form>
        </Card>
      </div>
    </DashboardLayout>
  );
};
