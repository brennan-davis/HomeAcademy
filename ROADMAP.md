# HomeAcademy Development Roadmap

## Current Status

**✅ Step 1: Authentication (COMPLETE)**
- Backend: User registration, login, JWT middleware, full test coverage
- Frontend: Ready for login/register UI implementation

## Development Tracks

The project is split into **Backend Track** (API development) and **Frontend Track** (UI development). You can focus on frontend while backend APIs are built as needed.

---

## Backend Track (API Development)

- **Step 2:** Family & Student API
  - POST/GET/PUT/DELETE endpoints for families
  - POST/GET/PUT/DELETE endpoints for students
  - Full test coverage

- **Step 3:** Attendance API
  - Daily attendance records (create, update, list)
  - Aggregation endpoints (totals, by date range)

- **Step 4:** Subjects & Lessons API
  - Subject CRUD per student
  - Lesson plan management
  - Scheduled lessons with status tracking

- **Step 5:** Compliance API
  - Get state requirements by state code
  - Calculate compliance status for family

- **Step 6:** Gradebook API
  - Record grades for assignments
  - Calculate GPA with weighting

- **Step 7:** Reports API
  - Generate PDF attendance reports
  - Generate PDF grade reports

- **Step 8:** Co-op API
  - Multi-family class management
  - Enrollment endpoints

---

## Frontend Track (UI Development) - FOCUS HERE

### **Step 2: Authentication UI**
- [ ] Login page (`/login`)
  - Email/password form with validation
  - Error handling
  - Redirect to dashboard on success
- [ ] Register page (`/register`)
  - Email/password/confirm password form
  - Role selection (Parent/Student)
  - Form validation
- [ ] AuthContext setup
  - Manage user state globally
  - Store JWT token
  - Handle logout
- [ ] Protected route wrapper
  - Redirect to login if not authenticated

### **Step 3: Dashboard Layout**
- [ ] Main app shell
  - Top navigation bar with user menu
  - Sidebar navigation
  - Logout functionality
- [ ] Routing setup
  - React Router with protected routes
  - Dashboard home page

### **Step 4: Family Setup Wizard**
- [ ] Create family flow
  - Family name
  - State selection (for compliance)
  - School year dates
- [ ] Add students to family
  - First/last name
  - Grade level
  - Date of birth (optional)

### **Step 5: Student Management**
- [ ] Student list view
  - Display all students in family
  - Edit/delete actions
- [ ] Add/Edit student modal
  - Form with validation
  - Save to backend

### **Step 6: Attendance Calendar**
- [ ] Calendar view (month/week)
  - Display attendance status per day
  - Color coding (present, absent, half-day, etc.)
- [ ] Mark attendance
  - Quick mark for today
  - Edit past attendance
  - Add notes (field trip, illness, etc.)
- [ ] Attendance summary
  - Total days present/absent
  - Hours tracked (if applicable)

### **Step 7: Subject Management**
- [ ] Subject list per student
  - View assigned subjects
  - Color coding for visual organization
- [ ] Add/Edit subjects
  - Subject name
  - Curriculum name
  - Color picker
  - Active/inactive status

### **Step 8: Lesson Planner**
- [ ] Calendar view for lessons
  - Week/month view
  - Color coded by subject
- [ ] Schedule lessons
  - Select subject
  - Set date/time
  - Add notes/materials
- [ ] Mark lessons complete
  - Update status
  - Track completion date

### **Step 9: Gradebook**
- [ ] Grade entry form
  - Select student and subject
  - Assignment title
  - Score and max score
  - Weight
- [ ] Grade list view
  - Filter by student/subject
  - Display calculated average
- [ ] GPA calculator
  - Display current GPA
  - Show breakdown by subject

### **Step 10: Compliance Dashboard**
- [ ] State requirements display
  - Show requirements for family's state
  - Required days/hours
  - Required subjects
  - Testing grades
- [ ] Progress tracking
  - Days completed vs required
  - Hours logged vs required
  - Subject coverage checklist

### **Step 11: Reports Viewer**
- [ ] Report selection
  - Choose report type
  - Select date range
  - Select student(s)
- [ ] PDF generation
  - Trigger backend PDF generation
  - Download/view PDF

### **Step 12: Co-op Features**
- [ ] Browse available co-op classes
  - List classes with details
  - Filter/search
- [ ] Enroll students
  - Select class and student
  - Confirm enrollment
- [ ] View class schedule
  - Integrated with lesson planner

---

## Recommended Development Flow

### For Frontend-Focused Development:
1. Build UI with mock data first
2. Request backend API endpoints as needed
3. Connect to real APIs once available
4. Iterate and refine UI/UX

### For Backend-Focused Development:
1. Design API endpoints for a feature
2. Implement with Prisma + Express
3. Write tests (aim for >80% coverage)
4. Document endpoints for frontend integration
