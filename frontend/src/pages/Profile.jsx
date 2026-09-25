import React, { useState, useEffect } from 'react';
import { User, Mail, Calendar, Shield, Save, AlertCircle } from 'lucide-react';
import { DashboardLayout } from '../layouts/DashboardLayout';
import { ModeratorDashboardLayout } from '../layouts/ModeratorDashboardLayout';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';

export const Profile = () => {
  const { user } = useAuth();
  
  // Select layout based on user role
  let Layout = DashboardLayout;
  if (user?.role === 'MODERATOR') {
    Layout = ModeratorDashboardLayout;
  } else if (user?.role === 'DEPARTMENT') {
    Layout = DepartmentDashboardLayout;
  }
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  const [editing, setEditing] = useState(false);
  const [editData, setEditData] = useState({
    name: '',
    email: ''
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const fetchProfile = async () => {
      setLoading(true);
      setError('');
      try {
        const res = await api.get('/auth/profile');
        setProfile(res.user);
        setEditData({
          name: res.user.name || '',
          email: res.user.email || ''
        });
      } catch (err) {
        setError('Unable to load profile.');
      } finally {
        setLoading(false);
      }
    };

    fetchProfile();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setEditData(prev => ({ ...prev, [name]: value }));
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    
    if (!editData.name || !editData.email) {
      setError('Name and email are required');
      return;
    }

    setSaving(true);
    try {
      const res = await api.patch('/auth/profile', editData);
      setProfile(res.user);
      setEditing(false);
      setSuccess('Profile updated successfully!');
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError(err.message || 'Failed to update profile.');
    } finally {
      setSaving(false);
    }
  };

  const handleCancel = () => {
    setEditing(false);
    setError('');
    setEditData({
      name: profile?.name || '',
      email: profile?.email || ''
    });
  };

  if (loading) {
    return (
      <Layout>
        <div style={{maxWidth: '800px', margin: '0 auto'}}>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '1.5rem'}}>
            My Profile
          </h1>
          <Card style={{padding: '2rem', textAlign: 'center', color: 'var(--text-secondary)'}}>
            Loading profile...
          </Card>
        </div>
      </Layout>
    );
  }

  if (error && !profile) {
    return (
      <Layout>
        <div style={{maxWidth: '800px', margin: '0 auto'}}>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', marginBottom: '1.5rem'}}>
            My Profile
          </h1>
          <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
              <AlertCircle size={40} />
              <div>
                <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Profile</h3>
                <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error}</p>
              </div>
            </div>
          </Card>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div style={{maxWidth: '800px', margin: '0 auto'}}>
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem'}}>
          <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: 0}}>
            My Profile
          </h1>
          {!editing && (
            <Button variant="primary" onClick={() => setEditing(true)}>
              Edit Profile
            </Button>
          )}
        </div>

        {success && (
          <div style={{backgroundColor: 'var(--success-100)', color: 'var(--success-700)', padding: '0.75rem', borderRadius: 'var(--border-radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem', textAlign: 'center'}}>
            {success}
          </div>
        )}

        {error && editing && (
          <div style={{backgroundColor: 'var(--danger-100)', color: 'var(--danger-700)', padding: '0.75rem', borderRadius: 'var(--border-radius-md)', marginBottom: '1.5rem', fontSize: '0.875rem', textAlign: 'center'}}>
            {error}
          </div>
        )}

        <Card style={{padding: '1.5rem'}}>
          {/* Profile Header */}
          <div style={{display: 'flex', alignItems: 'center', gap: '1rem', paddingBottom: '1rem', borderBottom: '1px solid var(--border-color)', marginBottom: '1rem'}}>
            <div style={{width: '56px', height: '56px', borderRadius: '50%', backgroundColor: 'var(--primary-100)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-700)', fontSize: '1.5rem', fontWeight: '600', flexShrink: 0}}>
              {profile?.name?.charAt(0).toUpperCase()}
            </div>
            <div style={{minWidth: 0}}>
              <h2 style={{margin: '0 0 0.125rem 0', fontSize: '1.25rem', color: 'var(--text-primary)'}}>{profile?.name}</h2>
              <p style={{margin: 0, color: 'var(--text-secondary)', fontSize: '0.875rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap'}}>{profile?.email}</p>
            </div>
          </div>

          {editing ? (
            <form onSubmit={handleSave} style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
              <Input 
                label="Full Name"
                name="name"
                value={editData.name}
                onChange={handleInputChange}
                required
              />
              
              <Input 
                label="Email Address"
                type="email"
                name="email"
                value={editData.email}
                onChange={handleInputChange}
                required
              />

              <div style={{display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem', paddingTop: '1rem', borderTop: '1px solid var(--border-color)'}}>
                <Button type="button" variant="secondary" onClick={handleCancel} disabled={saving}>
                  Cancel
                </Button>
                <Button type="submit" variant="primary" disabled={saving} style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                  <Save size={16} />
                  {saving ? 'Saving...' : 'Save Changes'}
                </Button>
              </div>
            </form>
          ) : (
            <div className="profile-details-grid">
              <div className="profile-detail-item">
                <div style={{display: 'flex', alignItems: 'center', gap: '0.375rem', color: 'var(--text-secondary)', fontSize: '0.8125rem', marginBottom: '0.375rem'}}>
                  <User size={14} />
                  <span>Full Name</span>
                </div>
                <p style={{margin: 0, fontWeight: '500', color: 'var(--text-primary)', fontSize: '0.9375rem'}}>{profile?.name}</p>
              </div>

              <div className="profile-detail-item">
                <div style={{display: 'flex', alignItems: 'center', gap: '0.375rem', color: 'var(--text-secondary)', fontSize: '0.8125rem', marginBottom: '0.375rem'}}>
                  <Mail size={14} />
                  <span>Email</span>
                </div>
                <p style={{margin: 0, fontWeight: '500', color: 'var(--text-primary)', fontSize: '0.9375rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap'}}>{profile?.email}</p>
              </div>

              <div className="profile-detail-item">
                <div style={{display: 'flex', alignItems: 'center', gap: '0.375rem', color: 'var(--text-secondary)', fontSize: '0.8125rem', marginBottom: '0.375rem'}}>
                  <Shield size={14} />
                  <span>Role</span>
                </div>
                <p style={{margin: 0, fontWeight: '500', color: 'var(--text-primary)', fontSize: '0.9375rem'}}>{profile?.role}</p>
              </div>

              <div className="profile-detail-item">
                <div style={{display: 'flex', alignItems: 'center', gap: '0.375rem', color: 'var(--text-secondary)', fontSize: '0.8125rem', marginBottom: '0.375rem'}}>
                  <Calendar size={14} />
                  <span>Member Since</span>
                </div>
                <p style={{margin: 0, fontWeight: '500', color: 'var(--text-primary)', fontSize: '0.9375rem'}}>
                  {profile?.createdAt ? new Date(profile.createdAt).toLocaleDateString() : 'N/A'}
                </p>
              </div>
            </div>
          )}
        </Card>
      </div>
    </Layout>
  );
};
