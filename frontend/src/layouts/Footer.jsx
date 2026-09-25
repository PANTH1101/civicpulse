import React from 'react';
import { Building2 } from 'lucide-react';
import './layouts.css';

export const Footer = () => {
  return (
    <footer className="footer">
      <div className="container footer-container">
        <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--primary-600)', fontWeight: '600'}}>
          <Building2 size={20} />
          <span>CivicPulse</span>
        </div>
        <p className="footer-text">
          Smart Municipal Services Management System.
        </p>
        <p className="footer-text" style={{fontSize: '0.75rem'}}>
          &copy; {new Date().getFullYear()} CivicPulse. All rights reserved.
        </p>
      </div>
    </footer>
  );
};
