# MentorMatch AI Enhanced - Installation Verification

cat("🔍 Verifying MentorMatch AI Enhanced installation...\n")

# Load required libraries for verification
library(DBI)
library(RSQLite)

# Check required packages
required_packages <- c("shiny", "bslib", "DBI", "RSQLite", "text2vec", "DT", "plotly", "shinyWidgets", "digest", "R6")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if (length(missing_packages) == 0) {
  cat("✅ All core packages installed\n")
} else {
  cat("❌ Missing packages:", paste(missing_packages, collapse = ", "), "\n")
}

# Check database
if (file.exists("mentormatch_enhanced.sqlite")) {
  con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
  tables <- dbListTables(con)
  expected_tables <- c("users", "students_enhanced", "mentor_profiles", "notifications")
  
  if (all(expected_tables %in% tables)) {
    cat("✅ Database properly initialized\n")
    
    # Check sample data
    mentor_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM mentor_profiles")$count
    student_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM students_enhanced")$count
    
    cat("📊 Sample data:", mentor_count, "mentors,", student_count, "students\n")
  } else {
    cat("❌ Database tables missing\n")
  }
  
  dbDisconnect(con)
} else {
  cat("❌ Database file not found\n")
}

# Check directories
if (dir.exists("www")) {
  cat("✅ Web assets directory created\n")
} else {
  cat("❌ www directory missing\n")
}

cat("\n🎯 Installation verification complete!\n")
cat("Run: Rscript start_enhanced.R to launch the application\n")

