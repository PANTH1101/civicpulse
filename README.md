# 🏛️ CivicPulse

> A comprehensive digital platform connecting citizens with municipal departments for efficient civic issue management and service delivery.

[![Production Ready](https://img.shields.io/badge/status-production%20ready-success)]()
[![Tests Passing](https://img.shields.io/badge/tests-100%25%20passing-brightgreen)]()
[![Node.js](https://img.shields.io/badge/node.js-v20+-339933?logo=node.js)]()
[![React](https://img.shields.io/badge/react-19.2-61DAFB?logo=react)]()
[![MongoDB](https://img.shields.io/badge/mongodb-6.0-47A248?logo=mongodb)]()

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [System Architecture](#-system-architecture)
- [Getting Started](#-getting-started)
- [User Roles](#-user-roles)
- [API Documentation](#-api-documentation)
- [Database Schema](#-database-schema)
- [Screenshots](#-screenshots)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

CivicPulse is a modern web application designed to bridge the gap between citizens and municipal services. It streamlines the process of reporting civic issues (potholes, broken streetlights, water leaks, etc.) and requesting municipal services (water connection, building permits, etc.) while providing departments with tools to efficiently manage and resolve these requests.

### Key Highlights

- 🎯 **35+ REST API Endpoints** - Comprehensive backend coverage
- 👥 **3 User Roles** - Citizen, Moderator, Department
- 🔔 **Real-time Notifications** - Keep users informed at every step
- 📸 **Image Upload Support** - Visual evidence for issues (Cloudinary CDN)
- 🔒 **JWT Authentication** - Secure, token-based auth
- ✅ **100% Test Coverage** - Production-ready reliability
- 📱 **Responsive UI** - Works on desktop, tablet, and mobile

---

## ✨ Features

### For Citizens 👨‍👩‍👧‍👦
- ✅ Report civic issues with photos and location
- ✅ Track issue status in real-time (Reported → Assigned → In Progress → Resolved)
- ✅ Request municipal services (birth certificate, water connection, etc.)
- ✅ Receive notifications on issue updates
- ✅ Provide feedback/ratings after resolution
- ✅ View public notices from municipality
- ✅ Manage profile and view submission history

### For Moderators 👮
- ✅ Review all reported civic issues
- ✅ Approve genuine issues and auto-assign to departments
- ✅ Reject spam/invalid issues with feedback
- ✅ View published public notices (read-only)
- ✅ Monitor overall system activity
- ✅ Receive notifications when issues are reported

### For Departments 🏢
- ✅ View issues assigned to their department
- ✅ Update issue status (Assigned → In Progress → Resolved)
- ✅ Accept/Reject service requests
- ✅ Upload resolution evidence (photos)
- ✅ Manage municipal service offerings
- ✅ Create and publish public notices
- ✅ Manage department-specific notices (drafts & published)
- ✅ Receive notifications on new assignments

---

## 🛠️ Tech Stack

### Backend
- **Runtime:** Node.js (v20+)
- **Framework:** Express.js 5.2
- **Database:** MongoDB 6.0 + Mongoose ODM
- **Authentication:** JWT (JSON Web Tokens) + bcryptjs
- **File Upload:** Multer + Cloudinary CDN
- **Environment:** dotenv

### Frontend
- **Framework:** React 19.2
- **Routing:** React Router DOM 7.18
- **Build Tool:** Vite 8.3
- **Icons:** Lucide React
- **Styling:** Custom CSS (CSS Variables + Modern Layout)
- **Linting:** OxLint

### DevOps & Tools
- **Version Control:** Git + GitHub
- **Development:** Nodemon (hot reload)
- **API Testing:** 116+ automated tests
- **Security:** CORS, input validation, role-based access control

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        FRONTEND (React)                      │
│  - Citizen Portal  - Moderator Dashboard  - Department UI   │
└────────────────────┬────────────────────────────────────────┘
                     │ REST API (JSON)
                     │
┌────────────────────▼────────────────────────────────────────┐
│                    BACKEND (Node.js/Express)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Auth Layer   │  │ Controllers  │  │  Middleware  │      │
│  │ (JWT)        │  │              │  │  (authCheck) │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Business Logic Layer                    │  │
│  │  - Issue Management  - Service Requests              │  │
│  │  - Auto-assignment   - Notifications                 │  │
│  └──────────────────────────────────────────────────────┘  │
└───────────────────┬──────────────────────────────────────┬──┘
                    │                                      │
        ┌───────────▼──────────┐              ┌───────────▼──────────┐
        │   MongoDB Database    │              │  Cloudinary CDN      │
        │  - 9 Collections      │              │  - Image Storage     │
        │  - Relationships      │              │  - Transformations   │
        └───────────────────────┘              └──────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

Before running this application, ensure you have:

- **Node.js** (v20 or higher) - [Download](https://nodejs.org/)
- **MongoDB** (v6.0 or higher) - [Download](https://www.mongodb.com/try/download/community)
- **Git** - [Download](https://git-scm.com/)
- **Cloudinary Account** (free) - [Sign up](https://cloudinary.com/)

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/PANTH1101/civicpulse.git
cd civicpulse
```

#### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

**Required Environment Variables (`.env`):**

```env
PORT=4000
MONGO_URI=mongodb://localhost:27017/civicpulse
JWT_SECRET=your_super_secret_jwt_key_here_change_in_production

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

#### 3. Seed the Database

```bash
# Seed departments (Water, Roads, Electricity, etc.)
npm run seed:departments

# Seed department users
npm run seed:department-users

# Seed municipal services
npm run seed:services
```

#### 4. Start Backend Server

```bash
# Development mode (with hot reload)
npm run dev

# Production mode
npm start
```

Backend will run on `http://localhost:4000`

#### 5. Frontend Setup

```bash
# Open new terminal, navigate to frontend directory
cd ../frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

Frontend will run on `http://localhost:5173`

---

## 👥 User Roles

### 🧑 Citizen
**Default Test User:**
```
Email: citizen@test.com
Password: password123
```

**Capabilities:**
- Report civic issues
- Request municipal services
- Track submissions
- View notifications
- Provide feedback

### 👮 Moderator
**Default Test User:**
```
Email: moderator@test.com
Password: password123
```

**Capabilities:**
- Review & approve/reject issues
- Auto-assign issues to departments
- Create public notices
- Monitor all activity

### 🏢 Department User
**Default Test User (Water Department):**
```
Email: water@dept.com
Password: password123
```

**Capabilities:**
- View assigned issues/requests
- Update work status
- Upload resolution evidence
- Accept/reject service requests

---

## 📡 API Documentation

### Base URL
```
http://localhost:4000/api
```

### Authentication
All protected routes require JWT token in header:
```
Authorization: Bearer <your_jwt_token>
```

### Key Endpoints

#### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - User login
- `GET /auth/me` - Get current user

#### Civic Issues
- `POST /issues` - Report new issue (Citizen)
- `GET /issues/my-issues` - Get user's issues (Citizen)
- `GET /issues/:id` - Get issue details
- `PATCH /issues/:id/status` - Update issue status (Department)

#### Moderator Actions
- `GET /issues/pending` - Get all pending issues (Moderator)
- `PATCH /issues/:id/approve` - Approve issue (Moderator)
- `PATCH /issues/:id/reject` - Reject issue (Moderator)

#### Municipal Services
- `GET /services` - Get all services
- `POST /services/requests` - Request a service (Citizen)
- `GET /services/requests/my` - Get user's requests (Citizen)

#### Department Operations
- `GET /departments/my-issues` - Get department's issues
- `GET /departments/service-requests` - Get department's service requests
- `PATCH /departments/issues/:id/status` - Update issue status

#### Public Notices
- `GET /notices` - Get all published notices (All authenticated users)
- `POST /notices` - Create notice draft (Department)
- `GET /notices/all` - Get department's notices (Department)
- `GET /notices/:id` - Get notice details (All authenticated users)
- `PATCH /notices/:id/publish` - Publish notice (Department)

#### Notifications
- `GET /notifications` - Get user's notifications
- `PATCH /notifications/:id/read` - Mark as read

**Full API documentation:** See `/docs` folder for detailed specs

---

## 🗄️ Database Schema

### Core Collections

#### 1. Users
```javascript
{
  name: String,
  email: String (unique),
  password: String (hashed),
  phone: String,
  address: String,
  role: Enum ['CITIZEN', 'MODERATOR', 'DEPARTMENT'],
  department: ObjectId (ref: Department) // for DEPARTMENT role
}
```

#### 2. CivicIssue
```javascript
{
  title: String,
  description: String,
  category: Enum (Road, Water, Electricity, etc.),
  location: String,
  imageUrl: String,
  status: Enum (REPORTED, ASSIGNED, IN_PROGRESS, RESOLVED, REJECTED),
  priority: Enum (LOW, MEDIUM, HIGH),
  reportedBy: ObjectId (ref: User),
  assignedDepartment: ObjectId (ref: Department),
  resolutionDetails: String,
  resolutionEvidence: String (image URL),
  rejectionReason: String
}
```

#### 3. ServiceRequest
```javascript
{
  citizen: ObjectId (ref: User),
  service: ObjectId (ref: MunicipalService),
  department: ObjectId (ref: Department),
  status: Enum (PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, REJECTED),
  requestDetails: String,
  documents: [String],
  completionDetails: String
}
```

#### 4. Department
```javascript
{
  name: String (unique),
  description: String,
  email: String,
  phone: String,
  categories: [String] // Issue categories this department handles
}
```

#### 5. MunicipalService
```javascript
{
  name: String,
  description: String,
  category: String,
  department: ObjectId (ref: Department),
  requiredDocuments: [String],
  processingTime: String,
  fees: Number
}
```

#### 6. PublicNotice
```javascript
{
  title: String,
  content: String,
  category: Enum (GENERAL, EMERGENCY, MAINTENANCE, EVENT, POLICY, ANNOUNCEMENT, OTHER),
  status: Enum (DRAFT, PUBLISHED),
  department_id: ObjectId (ref: Department),
  startDate: Date (optional),
  endDate: Date (optional),
  createdBy: ObjectId (ref: User), // Department user
  publishedBy: ObjectId (ref: User), // Department user
  publishedAt: Date
}
```

#### 7. Notification
```javascript
{
  user: ObjectId (ref: User),
  type: String,
  message: String,
  relatedId: ObjectId,
  isRead: Boolean,
  createdAt: Date
}
```

#### 8. Feedback
```javascript
{
  issue: ObjectId (ref: CivicIssue),
  citizen: ObjectId (ref: User),
  rating: Number (1-5),
  comment: String,
  category: String
}
```

---

## 📸 Screenshots

### Citizen Dashboard
> Clean, intuitive interface showing reported issues, service requests, and notifications

### Moderator Dashboard
> Powerful moderation tools with pending issues review and approval workflow

### Department Dashboard
> Organized view of assigned issues with status management and 2-column layout

### Issue Details
> Comprehensive issue view with images, location, status tracking, and resolution evidence

---

## 📁 Project Structure

```
civicpulse/
├── backend/                    # Node.js backend
│   ├── config/                 # Configuration files
│   │   ├── cloudinary.js       # Cloudinary setup
│   │   └── db.js               # MongoDB connection
│   ├── controllers/            # Request handlers
│   │   ├── authController.js
│   │   ├── issueController.js
│   │   ├── serviceController.js
│   │   ├── departmentController.js
│   │   ├── notificationController.js
│   │   ├── feedbackController.js
│   │   └── publicNoticeController.js
│   ├── middleware/             # Custom middleware
│   │   └── authMiddleware.js   # JWT verification
│   ├── models/                 # Mongoose schemas
│   │   ├── User.js
│   │   ├── CivicIssue.js
│   │   ├── ServiceRequest.js
│   │   ├── Department.js
│   │   ├── MunicipalService.js
│   │   ├── PublicNotice.js
│   │   ├── Notification.js
│   │   └── Feedback.js
│   ├── routes/                 # Express routes
│   │   ├── authRoutes.js
│   │   ├── issueRoutes.js
│   │   ├── serviceRoutes.js
│   │   ├── departmentRoutes.js
│   │   ├── notificationRoutes.js
│   │   ├── feedbackRoutes.js
│   │   └── publicNoticeRoutes.js
│   ├── seeders/                # Database seeders
│   │   ├── departmentSeeder.js
│   │   ├── departmentUserSeeder.js
│   │   ├── municipalServiceSeeder.js
│   │   └── createTestCitizen.js
│   ├── .env.example            # Environment template
│   ├── package.json
│   └── server.js               # Entry point
│
├── frontend/                   # React frontend
│   ├── public/                 # Static assets
│   ├── src/
│   │   ├── assets/             # Images, icons
│   │   ├── components/         # Reusable components
│   │   │   └── ui/             # UI components (Button, Card, Badge)
│   │   ├── context/            # React Context
│   │   │   └── AuthContext.jsx # Auth state management
│   │   ├── layouts/            # Layout components
│   │   │   ├── DashboardLayout.jsx
│   │   │   ├── ModeratorDashboardLayout.jsx
│   │   │   ├── DepartmentDashboardLayout.jsx
│   │   │   ├── Navbar.jsx
│   │   │   └── Footer.jsx
│   │   ├── pages/              # Page components
│   │   │   ├── Landing.jsx
│   │   │   ├── Login.jsx
│   │   │   ├── Register.jsx
│   │   │   ├── CitizenDashboard.jsx
│   │   │   ├── ModeratorDashboard.jsx
│   │   │   ├── DepartmentDashboard.jsx
│   │   │   ├── ReportIssue.jsx
│   │   │   ├── MyIssues.jsx
│   │   │   ├── IssueDetails.jsx
│   │   │   ├── MunicipalServices.jsx
│   │   │   ├── MyServiceRequests.jsx
│   │   │   ├── PublicNotices.jsx
│   │   │   ├── Notifications.jsx
│   │   │   └── Profile.jsx
│   │   ├── routes/             # Routing config
│   │   │   ├── AppRoutes.jsx
│   │   │   └── ProtectedRoute.jsx
│   │   ├── services/           # API services
│   │   │   └── api.js          # Axios instance
│   │   ├── App.jsx             # Root component
│   │   ├── main.jsx            # Entry point
│   │   └── index.css           # Global styles
│   ├── package.json
│   └── vite.config.js
│
└── docs/                       # Documentation
    ├── EXECUTIVE_SUMMARY.md
    ├── FACULTY_PRESENTATION.md
    ├── MANUAL_TEST_GUIDE.md
    ├── TASK1-12 Reports
    └── Implementation docs
```

---

## 📚 Documentation

Comprehensive documentation is available in the `/docs` folder:

- **[Executive Summary](docs/EXECUTIVE_SUMMARY.md)** - Quick project overview
- **[Faculty Presentation](docs/FACULTY_PRESENTATION.md)** - Detailed presentation deck
- **[Manual Test Guide](docs/MANUAL_TEST_GUIDE.md)** - Testing procedures
- **[Task Reports](docs/)** - Individual feature implementation reports
- **[Implementation Complete](docs/IMPLEMENTATION_COMPLETE.md)** - Final implementation report
- **[Validation Documentation](docs/VALIDATION_DOCUMENTATION.md)** - Testing and validation

---

## 🧪 Testing

The backend has been thoroughly tested with 116+ automated tests covering:

- ✅ Authentication & Authorization
- ✅ User Profile Management
- ✅ Civic Issue Workflow (Report → Assign → Resolve)
- ✅ Service Request Workflow
- ✅ Department Operations
- ✅ Moderator Actions
- ✅ Notifications System
- ✅ Image Upload (Cloudinary)
- ✅ Public Notices
- ✅ Feedback & Ratings

**All tests passing:** 100% ✅

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the ISC License.

---

## 👨‍💻 Author

**Panth Chauhan**
- GitHub: [@PANTH1101](https://github.com/PANTH1101)

---

## 🙏 Acknowledgments

- MongoDB for the excellent database
- Cloudinary for image hosting
- React team for the amazing framework
- Express.js for the robust backend framework

---

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check the documentation in `/docs`

---

<div align="center">

**Built with ❤️ for better civic engagement**

⭐ Star this repository if you find it helpful!

</div>
