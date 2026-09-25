import React, { useState, useEffect } from 'react';
import { Bell, Check, CheckCheck, AlertCircle, RefreshCw } from 'lucide-react';
import { DepartmentDashboardLayout } from '../layouts/DepartmentDashboardLayout';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { api } from '../services/api';

export const DepartmentNotifications = () => {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [markingAll, setMarkingAll] = useState(false);

  const fetchNotifications = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get('/notifications');
      setNotifications(res.notifications || []);
    } catch (err) {
      setError('Unable to load notifications.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  const markAsRead = async (notificationId) => {
    try {
      await api.patch(`/notifications/${notificationId}/read`);
      setNotifications(prev => 
        prev.map(n => n.id === notificationId ? { ...n, is_read: true } : n)
      );
    } catch (err) {
      console.error('Failed to mark notification as read');
    }
  };

  const markAllAsRead = async () => {
    setMarkingAll(true);
    try {
      await api.patch('/notifications/read-all');
      setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
    } catch (err) {
      setError('Failed to mark all as read');
    } finally {
      setMarkingAll(false);
    }
  };

  const unreadCount = notifications.filter(n => !n.is_read).length;

  return (
    <DepartmentDashboardLayout>
      <div style={{maxWidth: '900px', margin: '0 auto'}}>
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', gap: '1rem'}}>
          <div>
            <h1 style={{fontSize: '1.5rem', fontWeight: '700', color: 'var(--text-primary)', margin: '0 0 0.125rem 0'}}>
              Notifications
            </h1>
            {unreadCount > 0 && (
              <p style={{margin: 0, color: 'var(--text-secondary)', fontSize: '0.875rem'}}>
                You have {unreadCount} unread notification{unreadCount !== 1 ? 's' : ''}
              </p>
            )}
          </div>
          {unreadCount > 0 && (
            <Button 
              variant="outline" 
              onClick={markAllAsRead} 
              disabled={markingAll}
              style={{display: 'flex', alignItems: 'center', gap: '0.5rem', flexShrink: 0}}
            >
              <CheckCheck size={16} />
              Mark All as Read
            </Button>
          )}
        </div>

        {error ? (
          <Card style={{textAlign: 'center', padding: '3rem 1rem'}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem', color: 'var(--danger-600)'}}>
              <AlertCircle size={40} />
              <div>
                <h3 style={{margin: '0 0 0.5rem 0', color: 'var(--text-primary)'}}>Error Loading Notifications</h3>
                <p style={{margin: 0, color: 'var(--text-secondary)'}}>{error}</p>
              </div>
              <Button variant="outline" onClick={fetchNotifications} style={{display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '1rem'}}>
                <RefreshCw size={16} />
                Retry
              </Button>
            </div>
          </Card>
        ) : loading ? (
          <div style={{display: 'flex', flexDirection: 'column', gap: '0.875rem'}}>
            {[1, 2, 3, 4, 5].map(i => (
              <Card key={i} style={{padding: '1.125rem 1.25rem'}}>
                <div style={{height: '16px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '70%', marginBottom: '0.5rem'}} />
                <div style={{height: '12px', backgroundColor: 'var(--bg-secondary)', borderRadius: '4px', width: '35%'}} />
              </Card>
            ))}
          </div>
        ) : notifications.length === 0 ? (
          <Card style={{textAlign: 'center', padding: '3.5rem 1.5rem'}}>
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem'}}>
              <div style={{width: '56px', height: '56px', borderRadius: '50%', backgroundColor: 'var(--primary-50)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-600)'}}>
                <Bell size={28} />
              </div>
              <div>
                <h3 style={{margin: '0 0 0.375rem 0', color: 'var(--text-primary)', fontSize: '1rem', fontWeight: '600'}}>No notifications yet</h3>
                <p style={{margin: 0, maxWidth: '400px', color: 'var(--text-secondary)', fontSize: '0.875rem', lineHeight: 1.5}}>When you receive updates about assigned civic issues and service requests, they will appear here.</p>
              </div>
            </div>
          </Card>
        ) : (
          <div style={{display: 'flex', flexDirection: 'column', gap: '0.875rem'}}>
            {notifications.map(notif => (
              <Card 
                key={notif.id} 
                style={{
                  padding: '1.125rem 1.25rem',
                  backgroundColor: notif.is_read ? 'var(--bg-surface)' : 'var(--primary-25)',
                  borderColor: notif.is_read ? 'var(--border-color)' : 'var(--primary-200)',
                  borderRadius: '0.75rem',
                  position: 'relative'
                }}
              >
                <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '0.875rem'}}>
                  <div style={{flex: 1, minWidth: 0}}>
                    <div style={{display: 'flex', alignItems: 'flex-start', gap: '0.5rem', marginBottom: '0.375rem'}}>
                      {!notif.is_read && (
                        <div style={{width: '6px', height: '6px', borderRadius: '50%', backgroundColor: 'var(--primary-600)', flexShrink: 0, marginTop: '0.375rem'}} />
                      )}
                      <p style={{margin: 0, color: 'var(--text-primary)', fontSize: '0.9375rem', fontWeight: notif.is_read ? '400' : '500', lineHeight: 1.5}}>
                        {notif.message}
                      </p>
                    </div>
                    <p style={{margin: 0, fontSize: '0.8125rem', color: 'var(--text-secondary)', paddingLeft: notif.is_read ? 0 : '1rem'}}>
                      {new Date(notif.createdAt).toLocaleString()}
                    </p>
                  </div>
                  {!notif.is_read && (
                    <button
                      onClick={() => markAsRead(notif.id)}
                      className="notification-mark-read-btn"
                      title="Mark as read"
                      aria-label="Mark as read"
                    >
                      <Check size={16} />
                    </button>
                  )}
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </DepartmentDashboardLayout>
  );
};
