import React from 'react';
import { Link } from 'react-router-dom';
import { Navbar } from '../layouts/Navbar';
import { Footer } from '../layouts/Footer';
import { Button } from '../components/ui/Button';
import { Card } from '../components/ui/Card';
import { AlertCircle, FileText, Bell, MapPin } from 'lucide-react';
import './pages.css';

export const Landing = () => {
  return (
    <div style={{display: 'flex', flexDirection: 'column', minHeight: '100vh'}}>
      <Navbar />
      
      <main style={{flex: 1}}>
        {/* Hero Section */}
        <section id="home" className="hero-section">
          <div className="container">
            <h1 className="hero-title">
              Smart Civic Services,<br />
              <span>Simpler for Everyone.</span>
            </h1>
            <p className="hero-subtitle">
              CivicPulse connects citizens directly with municipal departments. Report issues, request services, and track progress all in one place.
            </p>
            <div className="hero-actions">
              <Link to="/register">
                <Button variant="primary" style={{padding: '0.75rem 1.5rem', fontSize: '1rem'}}>Get Started</Button>
              </Link>
              <Link to="/login">
                <Button variant="outline" style={{padding: '0.75rem 1.5rem', fontSize: '1rem'}}>Explore Services</Button>
              </Link>
            </div>
          </div>
        </section>
        
        {/* Features Section */}
        <section id="services" className="features-section">
          <div className="container">
            <h2 className="section-title">What CivicPulse Provides</h2>
            <div className="features-grid">
              <Card className="feature-card">
                <div className="feature-icon-wrapper">
                  <AlertCircle size={24} />
                </div>
                <h3 className="feature-title">Report Issues</h3>
                <p className="feature-desc">Report civic problems like potholes or broken streetlights and track their resolution.</p>
              </Card>
              
              <Card className="feature-card">
                <div className="feature-icon-wrapper">
                  <FileText size={24} />
                </div>
                <h3 className="feature-title">Municipal Services</h3>
                <p className="feature-desc">Request certificates, permits, and other municipal services from the appropriate department.</p>
              </Card>
              
              <Card className="feature-card">
                <div className="feature-icon-wrapper">
                  <MapPin size={24} />
                </div>
                <h3 className="feature-title">Track Progress</h3>
                <p className="feature-desc">Follow issues and service requests from submission to completion.</p>
              </Card>
              
              <Card className="feature-card">
                <div className="feature-icon-wrapper">
                  <Bell size={24} />
                </div>
                <h3 className="feature-title">Stay Informed</h3>
                <p className="feature-desc">Receive public notices and important notifications about your area.</p>
              </Card>
            </div>
          </div>
        </section>
        
        {/* How It Works Section */}
        <section id="about" className="how-it-works-section">
          <div className="container">
            <h2 className="section-title">About CivicPulse</h2>
            <p style={{
              textAlign: 'center',
              maxWidth: '700px',
              margin: '0 auto 3rem',
              color: 'var(--text-secondary)',
              fontSize: '1rem',
              lineHeight: '1.6'
            }}>
              CivicPulse is a modern platform connecting citizens with their municipal government. 
              We streamline civic engagement by making it easy to report issues, request services, 
              and stay informed about your community.
            </p>
            <h3 className="section-title" style={{fontSize: '1.5rem', marginTop: '2rem'}}>How It Works</h3>
            <div className="steps-grid">
              <div>
                <div className="step-number">1</div>
                <h4 className="step-title">Report / Request</h4>
                <p className="text-secondary" style={{fontSize: '0.875rem'}}>Submit your issue or request securely.</p>
              </div>
              <div>
                <div className="step-number">2</div>
                <h4 className="step-title">Team Processes</h4>
                <p className="text-secondary" style={{fontSize: '0.875rem'}}>Municipal staff review and assign the work.</p>
              </div>
              <div>
                <div className="step-number">3</div>
                <h4 className="step-title">Track Progress</h4>
                <p className="text-secondary" style={{fontSize: '0.875rem'}}>Get real-time updates on status changes.</p>
              </div>
              <div>
                <div className="step-number">4</div>
                <h4 className="step-title">Get Resolution</h4>
                <p className="text-secondary" style={{fontSize: '0.875rem'}}>Issue is resolved and documented.</p>
              </div>
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
};
