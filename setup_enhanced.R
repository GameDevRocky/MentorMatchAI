# MentorMatch AI Enhanced - Setup Script
# This script installs all required packages and sets up the enhanced application

cat("🚀 Setting up MentorMatch AI Enhanced...\n")

# Required packages
required_packages <- c(
  "shiny",           # Core Shiny framework
  "bslib",           # Bootstrap themes
  "DBI",             # Database interface
  "RSQLite",         # SQLite database
  "text2vec",        # Text analysis and semantic matching
  "Matrix",          # Matrix operations
  "proxy",           # Distance calculations
  "stopwords",       # Text preprocessing
  "DT",              # Data tables
  "plotly",          # Interactive plots
  "shinyWidgets",    # Enhanced UI widgets
  "shinydashboard",  # Dashboard components
  "shinyalert",      # Alert notifications
  "digest",          # Password hashing
  "R6",              # Object-oriented programming
  "glue",            # String interpolation
  "mailR",           # SMTP email sending
  "stringr",         # String manipulation
  "dplyr",           # Data manipulation
  "ggplot2",         # Plotting
  "jsonlite",        # JSON handling
  "httr",            # HTTP requests
  "magrittr"         # Pipe operators
)

# Function to install missing packages
install_missing_packages <- function(packages) {
  missing_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  
  if (length(missing_packages) > 0) {
    cat("📦 Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
    
    # Special handling for packages that might need different installation
    for (pkg in missing_packages) {
      tryCatch({
        if (pkg == "mailR") {
          # mailR might need special installation
          if (!requireNamespace("rJava", quietly = TRUE)) {
            install.packages("rJava")
          }
          install.packages("mailR")
        } else {
          install.packages(pkg, dependencies = TRUE)
        }
        cat("✅ Installed:", pkg, "\n")
      }, error = function(e) {
        cat("❌ Failed to install", pkg, ":", e$message, "\n")
        cat("   You may need to install this manually or skip email functionality\n")
      })
    }
  } else {
    cat("✅ All required packages are already installed\n")
  }
}

# Install missing packages
install_missing_packages(required_packages)

# Create necessary directories
cat("📁 Creating directories...\n")
dir.create("www", showWarnings = FALSE)
dir.create("www/uploads", showWarnings = FALSE, recursive = TRUE)
dir.create("logs", showWarnings = FALSE)

# Initialize database with sample data
cat("🗃️ Setting up enhanced database...\n")

# Source the enhanced app to run initialization
source("app_enhanced.R", local = TRUE)

# Add sample data
cat("📊 Adding sample data...\n")

con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")

# Create admin user
admin_hash <- digest::digest("mentormatch2024", algo = "sha256")
dbExecute(con, "INSERT OR IGNORE INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)",
          params = list("admin", "admin@mentormatch.ai", admin_hash, "admin"))

# Sample mentor data
sample_mentors <- data.frame(
  name = c("Dr. Sarah Chen", "Marcus Rodriguez", "Emily Johnson", "David Kim", "Rachel Thompson"),
  email = c("sarah.chen@tech.com", "marcus.r@startup.io", "emily.j@corp.com", "david.k@uni.edu", "rachel.t@design.co"),
  title = c("Senior Data Scientist", "Tech Entrepreneur", "Marketing Director", "CS Professor", "UX Design Lead"),
  company = c("TechCorp", "InnovateLabs", "Global Marketing Inc", "State University", "Design Studio"),
  industry = c("Technology & Software", "Technology & Software", "Business & Finance", "Education & Academia", "Creative & Media"),
  experience_years = c("5-10 years", "10-15 years", "3-5 years", "15+ years", "5-10 years"),
  location = c("San Francisco, CA", "Austin, TX", "New York, NY", "Boston, MA", "Los Angeles, CA"),
  bio = c(
    "Experienced data scientist specializing in machine learning and AI applications in healthcare and fintech.",
    "Serial entrepreneur with 3 successful exits. Passionate about helping the next generation of founders.",
    "Marketing executive with expertise in digital strategy, brand building, and customer acquisition.",
    "Computer Science professor and researcher focusing on algorithms and software engineering best practices.",
    "Creative leader in UX/UI design with experience at both startups and Fortune 500 companies."
  ),
  rating = c(4.8, 4.9, 4.6, 4.7, 4.5),
  total_reviews = c(24, 31, 18, 42, 16),
  verified = c(1, 1, 1, 1, 1),
  stringsAsFactors = FALSE
)

# Insert sample mentors
for (i in 1:nrow(sample_mentors)) {
  mentor <- sample_mentors[i, ]
  dbExecute(con, 
    "INSERT OR IGNORE INTO mentor_profiles (name, email, title, company, industry, experience_years, location, bio, rating, total_reviews, verified) 
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    params = list(mentor$name, mentor$email, mentor$title, mentor$company, mentor$industry, 
                 mentor$experience_years, mentor$location, mentor$bio, mentor$rating, mentor$total_reviews, mentor$verified)
  )
}

# Sample student data
sample_students <- data.frame(
  name = c("Alex Thompson", "Maya Patel", "Jordan Williams", "Casey Chen"),
  email = c("alex.t@student.edu", "maya.p@student.edu", "jordan.w@student.edu", "casey.c@student.edu"),
  education_level = c("Undergraduate", "Graduate Student", "Recent Graduate", "Undergraduate"),
  field_of_study = c("Computer Science", "Business Administration", "Engineering", "Psychology"),
  career_interest = c("Technology & Software", "Business & Finance", "Engineering & Manufacturing", "Healthcare & Medicine"),
  stringsAsFactors = FALSE
)

# Insert sample students
for (i in 1:nrow(sample_students)) {
  student <- sample_students[i, ]
  dbExecute(con, 
    "INSERT OR IGNORE INTO students_enhanced (name, email, education_level, field_of_study, career_interest) 
     VALUES (?, ?, ?, ?, ?)",
    params = list(student$name, student$email, student$education_level, student$field_of_study, student$career_interest)
  )
}

dbDisconnect(con)

# Create environment configuration file
cat("⚙️ Creating environment configuration...\n")

env_config <- '# MentorMatch AI Enhanced - Environment Configuration
# Copy this file to .env and update with your actual credentials

# SMTP Email Configuration (for production)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_TLS=TRUE

# Database Configuration
DB_PATH=mentormatch_enhanced.sqlite

# Admin Configuration
ADMIN_EMAIL=admin@mentormatch.ai

# Application Configuration
APP_PORT=3851
APP_HOST=127.0.0.1

# Feature Flags
ENABLE_SMTP=FALSE
ENABLE_NOTIFICATIONS=TRUE
ENABLE_ANALYTICS=TRUE
ENABLE_PWA=TRUE

# Security
SESSION_TIMEOUT=3600
PASSWORD_MIN_LENGTH=6
'

writeLines(env_config, "env.example")

# Create startup script
cat("🎬 Creating startup script...\n")

startup_script <- '#!/usr/bin/env Rscript

# MentorMatch AI Enhanced - Startup Script

cat("🎯 Starting MentorMatch AI Enhanced...\\n")

# Load environment variables
if (file.exists(".env")) {
  readRenviron(".env")
  cat("✅ Loaded environment configuration\\n")
} else {
  cat("⚠️  No .env file found. Using default configuration\\n")
  cat("   Copy env.example to .env and configure for production\\n")
}

# Set default values
port <- as.numeric(Sys.getenv("APP_PORT", "3851"))
host <- Sys.getenv("APP_HOST", "127.0.0.1")

# Load required libraries
suppressPackageStartupMessages({
  library(shiny)
})

cat("🚀 Launching application on", paste0("http://", host, ":", port), "\\n")
cat("🔐 Admin credentials: admin / mentormatch2024\\n")
cat("📧 SMTP:", if (Sys.getenv("ENABLE_SMTP", "FALSE") == "TRUE") "Enabled" else "Console mode", "\\n")

# Run the application
runApp("app_enhanced.R", host = host, port = port, launch.browser = TRUE)
'

writeLines(startup_script, "start_enhanced.R")
Sys.chmod("start_enhanced.R", mode = "0755")

# Create installation verification script
cat("🔍 Creating verification script...\n")

verify_script <- '# MentorMatch AI Enhanced - Installation Verification

cat("🔍 Verifying MentorMatch AI Enhanced installation...\\n")

# Check required packages
required_packages <- c("shiny", "bslib", "DBI", "RSQLite", "text2vec", "DT", "plotly", "shinyWidgets", "digest", "R6")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if (length(missing_packages) == 0) {
  cat("✅ All core packages installed\\n")
} else {
  cat("❌ Missing packages:", paste(missing_packages, collapse = ", "), "\\n")
}

# Check database
if (file.exists("mentormatch_enhanced.sqlite")) {
  con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
  tables <- dbListTables(con)
  expected_tables <- c("users", "students_enhanced", "mentor_profiles", "notifications")
  
  if (all(expected_tables %in% tables)) {
    cat("✅ Database properly initialized\\n")
    
    # Check sample data
    mentor_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM mentor_profiles")$count
    student_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM students_enhanced")$count
    
    cat("📊 Sample data:", mentor_count, "mentors,", student_count, "students\\n")
  } else {
    cat("❌ Database tables missing\\n")
  }
  
  dbDisconnect(con)
} else {
  cat("❌ Database file not found\\n")
}

# Check directories
if (dir.exists("www")) {
  cat("✅ Web assets directory created\\n")
} else {
  cat("❌ www directory missing\\n")
}

cat("\\n🎯 Installation verification complete!\\n")
cat("Run: Rscript start_enhanced.R to launch the application\\n")
'

writeLines(verify_script, "verify_installation.R")

# Create comprehensive documentation
cat("📚 Creating documentation...\n")

readme_content <- '# MentorMatch AI Enhanced

## 🚀 Next-Generation Mentorship Platform

MentorMatch AI Enhanced is a comprehensive mentorship platform that combines advanced AI technology with modern web features, user authentication, notification systems, and professional-grade functionality.

## ✨ Enhanced Features

### 🔐 User Authentication & Profiles
- Secure user registration and login system
- Password hashing with SHA-256
- Role-based access control (Student/Mentor/Admin)
- Profile image upload functionality
- Comprehensive profile management

### 📧 SMTP Email Integration
- Production-ready email system
- Beautiful HTML email templates
- Welcome emails for new users
- Match notification emails
- Confirmation emails
- Admin alert notifications

### 📱 Mobile & PWA Support
- Responsive design for all devices
- Progressive Web App (PWA) functionality
- Mobile-optimized interface
- Offline capability support

### 🔍 Advanced Search & Filtering
- Industry-based filtering
- Experience level filtering
- Location-based search
- Rating and availability filters
- Real-time search results

### 🔔 Notification System
- Real-time in-app notifications
- Email notification integration
- Notification history
- Read/unread status tracking

### ⭐ Rating & Review System
- Mentor rating system
- Review collection and display
- Verification badges
- Performance metrics

### 📊 Enhanced Analytics
- Comprehensive admin dashboard
- User engagement metrics
- Match success rates
- Platform usage statistics
- Real-time data visualization

### 🛡️ Security Features
- Secure password hashing
- Session management
- Input validation and sanitization
- SQL injection prevention
- XSS protection

## 🛠 Installation

### Prerequisites
- R (version 4.0 or higher)
- RStudio (recommended)

### Quick Setup
1. Clone or download the enhanced MentorMatch AI files
2. Run the setup script:
   ```r
   source("setup_enhanced.R")
   ```
3. Verify installation:
   ```r
   source("verify_installation.R")
   ```
4. Start the application:
   ```r
   source("start_enhanced.R")
   ```

### Manual Installation
If you prefer manual installation:

```r
# Install required packages
install.packages(c(
  "shiny", "bslib", "DBI", "RSQLite", "text2vec", 
  "Matrix", "proxy", "stopwords", "DT", "plotly",
  "shinyWidgets", "shinydashboard", "shinyalert",
  "digest", "R6", "glue", "mailR"
))

# Run the enhanced app
shiny::runApp("app_enhanced.R", port = 3851)
```

## ⚙️ Configuration

### Environment Setup
1. Copy `env.example` to `.env`
2. Update the configuration values:

```bash
# SMTP Configuration for production emails
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Enable/disable features
ENABLE_SMTP=TRUE
ENABLE_NOTIFICATIONS=TRUE
ENABLE_PWA=TRUE
```

### SMTP Email Setup
For production email functionality:

1. **Gmail Setup:**
   - Enable 2-factor authentication
   - Generate an app-specific password
   - Update SMTP_USERNAME and SMTP_PASSWORD in .env

2. **Other Email Providers:**
   - Update SMTP_HOST and SMTP_PORT in enhanced_email_utils.R
   - Configure authentication credentials

## 🎯 Usage

### For Students
1. Register with student role
2. Complete your profile
3. Browse mentors using advanced search
4. Connect with mentors that match your goals
5. Receive email confirmations and notifications

### For Mentors
1. Register with mentor role
2. Complete your professional profile
3. Set availability and mentoring preferences
4. Receive match notifications
5. Connect with interested students

### For Administrators
1. Access admin panel with floating action button (⚙️)
2. Login with credentials: admin / mentormatch2024
3. View comprehensive analytics
4. Manage users and system settings
5. Monitor platform performance

## 📊 Database Schema

The enhanced version uses a comprehensive SQLite database with the following tables:

- **users**: Authentication and basic user info
- **students_enhanced**: Detailed student profiles
- **mentor_profiles**: Comprehensive mentor information
- **mentor_matches**: Match tracking and history
- **notifications**: Notification system
- **reviews**: Rating and review system
- **analytics**: Platform usage tracking

## 🔧 Advanced Features

### PWA Installation
Users can install the app on their mobile devices:
1. Visit the app in Chrome/Safari
2. Look for "Add to Home Screen" prompt
3. Install for native app experience

### API Integration
The platform is designed to support future API integrations:
- Third-party authentication (Google, LinkedIn)
- Calendar integration
- Video call scheduling
- Payment processing

### Analytics Dashboard
Comprehensive metrics including:
- User registration trends
- Match success rates
- Geographic distribution
- Industry analytics
- Performance metrics

## 🛡️ Security Best Practices

- Passwords are hashed using SHA-256
- SQL injection prevention with parameterized queries
- XSS protection with input sanitization
- Session management and timeouts
- Environment variable protection

## 🚀 Deployment

### Local Development
```bash
Rscript start_enhanced.R
```

### Production Deployment
1. Configure production SMTP settings
2. Set up proper database backups
3. Configure reverse proxy (nginx/Apache)
4. Enable HTTPS/SSL
5. Set up monitoring and logging

## 📞 Support

### Default Credentials
- **Admin**: admin / mentormatch2024
- **Database**: mentormatch_enhanced.sqlite

### Troubleshooting
- Check `verify_installation.R` for setup issues
- Review console output for error messages
- Ensure all required packages are installed
- Verify database permissions

## 📈 Future Enhancements

- Video call integration
- Calendar scheduling
- Payment processing
- Machine learning improvements
- Multi-language support
- Advanced matching algorithms

## 🤝 Contributing

This enhanced version provides a solid foundation for further development. Key areas for contribution:
- Additional email templates
- Enhanced UI components
- Advanced analytics features
- Integration modules
- Performance optimizations

---

**MentorMatch AI Enhanced** - Connecting the future, one mentor at a time. 🎯
'

writeLines(readme_content, "README_ENHANCED.md")

# Final setup completion
cat("\n✅ Enhanced MentorMatch AI setup complete!\n")
cat("\n📋 Setup Summary:\n")
cat("   📦 Packages installed\n")
cat("   🗃️ Database initialized with sample data\n")
cat("   📁 Directories created\n")
cat("   ⚙️ Configuration files created\n")
cat("   📚 Documentation generated\n")

cat("\n🚀 Next Steps:\n")
cat("   1. Run: source('verify_installation.R') to verify setup\n")
cat("   2. Configure: Copy env.example to .env and update settings\n")
cat("   3. Launch: source('start_enhanced.R') to start the application\n")
cat("   4. Access: http://127.0.0.1:3851\n")
cat("   5. Admin: Click ⚙️ button, login with admin/mentormatch2024\n")

cat("\n📧 Email Setup (Optional):\n")
cat("   - Update SMTP credentials in .env file\n")
cat("   - Set ENABLE_SMTP=TRUE for production emails\n")

cat("\n🎯 Happy mentoring! 🎯\n") 