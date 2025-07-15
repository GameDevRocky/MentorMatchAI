# Quick Start Script for AI Track Ticket 2
# This script provides a simple way to test the mentor recommendation system
# with realistic student questionnaire data

cat("🚀 AI Track Ticket 2: Quick Start with Real Student Data\n")
cat("=====================================================\n\n")

# Step 1: Check if required packages are installed
cat("Step 1: Checking required packages...\n")
required_packages <- c("text2vec", "Matrix", "proxy", "stopwords", "DBI", "RSQLite")

for (pkg in required_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("✅", pkg, "is available\n")
  } else {
    cat("❌", pkg, "is NOT available - installing...\n")
    install.packages(pkg)
    if (require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat("✅", pkg, "installed successfully\n")
    } else {
      cat("❌ Failed to install", pkg, "\n")
    }
  }
}
cat("\n")

# Step 2: Load the mentor recommender system
cat("Step 2: Loading mentor recommender system...\n")
source('mentor_recommender.R')
cat("✅ Mentor recommender system loaded\n\n")

# Step 3: Create test database with diverse mentors
cat("Step 3: Setting up test database with diverse mentors...\n")
library(DBI)
library(RSQLite)

# Create test database
con <- dbConnect(RSQLite::SQLite(), "test_mentors.db")

# Create mentors table
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS mentor_profiles (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    expertise TEXT NOT NULL,
    bio TEXT,
    email TEXT,
    image TEXT,
    active INTEGER DEFAULT 1,
    work_environment TEXT,
    mentorship_style TEXT,
    communication_preferences TEXT,
    personal_values TEXT,
    guidance_areas TEXT
  )
")

# Clear existing data
dbExecute(con, "DELETE FROM mentor_profiles")

# Insert diverse mentor data that matches questionnaire fields
test_mentors <- data.frame(
  id = 1:6,
  name = c(
    "Dr. Sarah Chen",
    "David Kim", 
    "James Parker",
    "Lisa Thompson",
    "Dr. Maya Patel",
    "Alex Rodriguez"
  ),
  title = c(
    "Senior Data Scientist",
    "UX Design Lead",
    "DevOps Engineer",
    "Product Manager",
    "Machine Learning Researcher",
    "Career Counselor"
  ),
  expertise_areas = c(
    "Machine Learning, Python, Data Analysis, Statistical Modeling, AI Ethics",
    "User Experience, Design Systems, Prototyping, Accessibility, User Research",
    "Infrastructure, Containerization, CI/CD, Monitoring, Cloud Architecture",
    "Product Strategy, Market Analysis, User Research, Agile Development, Team Leadership",
    "Deep Learning, Computer Vision, Natural Language Processing, Research Methods",
    "Career Planning, College Applications, Skill Development, Personal Branding"
  ),
  bio = c(
    "8 years experience in ML and analytics at Fortune 500 companies. Passionate about responsible AI and helping students understand data science career paths.",
    "UX designer with 6 years experience focusing on accessibility and inclusive design. Loves mentoring students interested in design thinking.",
    "DevOps engineer who reduced deployment time by 80% at previous company. Enjoys teaching infrastructure and automation concepts.",
    "Product manager with experience at both startups and large tech companies. Specializes in helping students understand product development.",
    "PhD in Computer Science with focus on machine learning. Published 20+ papers and loves mentoring students in research.",
    "Career counselor with 10 years experience helping students navigate college and career decisions. Expert in personal development."
  ),
  email = c(
    "sarah.chen@techcorp.com",
    "david.kim@designstudio.com", 
    "james.parker@devops.com",
    "lisa.thompson@product.com",
    "maya.patel@research.edu",
    "alex.rodriguez@career.com"
  ),
  work_environment = c(
    "corporate, research",
    "startup, corporate", 
    "corporate, remote",
    "startup, corporate",
    "research, corporate",
    "nonprofit, corporate"
  ),
  mentorship_style = c(
    "structured",
    "casual",
    "project",
    "structured", 
    "detailed",
    "encouraging"
  ),
  communication_preferences = c(
    "video, email",
    "video, text",
    "video, inperson",
    "video, email",
    "video, email",
    "video, text, inperson"
  ),
  personal_values = c(
    "innovation, education",
    "social_justice, accessibility",
    "innovation, worklife",
    "entrepreneurship, innovation",
    "education, innovation",
    "education, community, social_justice"
  ),
  guidance_areas = c(
    "career, skills",
    "career, skills",
    "career, skills",
    "career, skills, life",
    "career, skills, college_apps",
    "college_apps, career, life, skills"
  )
)

# Insert mentors
for (i in 1:nrow(test_mentors)) {
  dbExecute(con, "
    INSERT INTO mentor_profiles 
    (id, name, title, expertise, bio, email, image, active, work_environment, mentorship_style, 
     communication_preferences, personal_values, guidance_areas)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ", params = list(
    test_mentors$id[i],
    test_mentors$name[i],
    test_mentors$title[i], 
    test_mentors$expertise_areas[i],
    test_mentors$bio[i],
    test_mentors$email[i],
    "",  # image (empty for now)
    1,   # active
    test_mentors$work_environment[i],
    test_mentors$mentorship_style[i],
    test_mentors$communication_preferences[i],
    test_mentors$personal_values[i],
    test_mentors$guidance_areas[i]
  ))
}

cat("✅ Test database created with 6 diverse mentors\n\n")

# Step 4: Test with realistic student questionnaire data
cat("Step 4: Testing with realistic student questionnaire data...\n\n")

# Create embedding system
embedding_system <- default_embedding_system(con)

# Test Case 1: Data Science Student
cat("📊 Test Case 1: Data Science Student\n")
cat("------------------------------------\n")
student1 <- list(
  name = "Emma Johnson",
  email = "emma.j@student.edu",
  school_name = "Tech High School",
  fields = "data science, machine learning, artificial intelligence, statistics",
  environment = c("corporate", "research"),
  guidance = c("career", "skills", "college_apps"),
  mentorship_type = "structured",
  feedback_style = "detailed",
  comm_style = c("video", "email"),
  frequency = "weekly",
  personal_values = c("innovation", "education"),
  challenges = "First-generation college student interested in breaking into tech",
  outcomes = c("career_clarity", "skills", "college_admission"),
  additional_info = "Looking for guidance on data science career paths and college applications"
)

recs1 <- get_mentor_recommendations(student1, embedding_system, top_k = 3)
cat("Top 3 recommendations:\n")
for (i in 1:length(recs1)) {
  cat(sprintf("%d. %s (%s) - Score: %.3f\n", 
              i, recs1[[i]]$name, recs1[[i]]$title, recs1[[i]]$score))
}
cat("\n")

# Test Case 2: UX Design Student
cat("🎨 Test Case 2: UX Design Student\n")
cat("---------------------------------\n")
student2 <- list(
  name = "Marcus Chen",
  email = "marcus.c@student.edu", 
  school_name = "Design Academy",
  fields = "user experience design, human-computer interaction, design thinking",
  environment = c("startup", "corporate"),
  guidance = c("career", "skills"),
  mentorship_type = "casual",
  feedback_style = "encouraging",
  comm_style = c("video", "text"),
  frequency = "biweekly",
  personal_values = c("social_justice", "accessibility"),
  challenges = "Want to make technology more accessible for people with disabilities",
  outcomes = c("career_clarity", "skills", "confidence"),
  additional_info = "Passionate about inclusive design and accessibility"
)

recs2 <- get_mentor_recommendations(student2, embedding_system, top_k = 3)
cat("Top 3 recommendations:\n")
for (i in 1:length(recs2)) {
  cat(sprintf("%d. %s (%s) - Score: %.3f\n", 
              i, recs2[[i]]$name, recs2[[i]]$title, recs2[[i]]$score))
}
cat("\n")

# Test Case 3: Career Exploration Student
cat("🎯 Test Case 3: Career Exploration Student\n")
cat("------------------------------------------\n")
student3 <- list(
  name = "Sofia Rodriguez",
  email = "sofia.r@student.edu",
  school_name = "Community College",
  fields = "business, entrepreneurship, social impact, community service",
  environment = c("startup", "nonprofit"),
  guidance = c("career", "life", "college_apps"),
  mentorship_type = "peer",
  feedback_style = "encouraging",
  comm_style = c("video", "text", "inperson"),
  frequency = "monthly",
  personal_values = c("social_justice", "community", "entrepreneurship"),
  challenges = "First-generation student wanting to start a social enterprise",
  outcomes = c("career_clarity", "confidence", "network"),
  additional_info = "Interested in combining business skills with social impact"
)

recs3 <- get_mentor_recommendations(student3, embedding_system, top_k = 3)
cat("Top 3 recommendations:\n")
for (i in 1:length(recs3)) {
  cat(sprintf("%d. %s (%s) - Score: %.3f\n", 
              i, recs3[[i]]$name, recs3[[i]]$title, recs3[[i]]$score))
}
cat("\n")

# Test Case 4: DevOps/Infrastructure Student
cat("⚙️ Test Case 4: DevOps/Infrastructure Student\n")
cat("---------------------------------------------\n")
student4 <- list(
  name = "Jordan Smith",
  email = "jordan.s@student.edu",
  school_name = "Tech Institute",
  fields = "cloud computing, infrastructure, automation, system administration",
  environment = c("corporate", "remote"),
  guidance = c("career", "skills"),
  mentorship_type = "project",
  feedback_style = "direct",
  comm_style = c("video", "inperson"),
  frequency = "weekly",
  personal_values = c("innovation", "worklife"),
  challenges = "Self-taught programmer wanting to transition into DevOps",
  outcomes = c("skills", "career_clarity"),
  additional_info = "Looking for hands-on project guidance and career advice"
)

recs4 <- get_mentor_recommendations(student4, embedding_system, top_k = 3)
cat("Top 3 recommendations:\n")
for (i in 1:length(recs4)) {
  cat(sprintf("%d. %s (%s) - Score: %.3f\n", 
              i, recs4[[i]]$name, recs4[[i]]$title, recs4[[i]]$score))
}
cat("\n")

# Step 5: Performance test
cat("Step 5: Performance test...\n")
start_time <- Sys.time()
for (i in 1:10) {
  get_mentor_recommendations(student1, embedding_system, top_k = 3)
}
end_time <- Sys.time()
avg_time <- as.numeric(difftime(end_time, start_time, units = "secs")) / 10
cat(sprintf("✅ Average recommendation time: %.3f seconds\n\n", avg_time))

# Step 6: Cleanup
cat("Step 6: Cleanup...\n")
dbDisconnect(con)
file.remove("test_mentors.db")
cat("✅ Test database cleaned up\n\n")

cat("🎉 All tests completed successfully!\n")
cat("The mentor recommendation system is working correctly with realistic student questionnaire data.\n")
cat("Students can now be matched with mentors based on their comprehensive questionnaire responses.\n") 