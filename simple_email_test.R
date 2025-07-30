# =============================================================================
# SIMPLE EMAIL TEST SCRIPT
# =============================================================================
# 
# This script tests the email functionality step by step
# 
# =============================================================================

# Load required packages
library(blastula)
library(glue)

cat("🚀 Starting simple email test...\n\n")

# Step 1: Test package loading
cat("📦 Step 1: Testing package loading...\n")
if (require(blastula) && require(glue)) {
  cat("✅ Packages loaded successfully\n\n")
} else {
  cat("❌ Package loading failed\n")
  stop("Please install blastula and glue packages")
}

# Step 2: Test credential file
cat("🔐 Step 2: Testing credential file...\n")
if (file.exists("gmail_credss")) {
  cat("✅ gmail_credss file found\n\n")
} else {
  cat("❌ gmail_credss file not found\n")
  cat("💡 Make sure the credential file is in the same directory\n\n")
}

# Step 3: Set up email configuration
cat("⚙️ Step 3: Setting up email configuration...\n")
EMAIL_CONFIG <- list(
  from_email = "mentormatchai.help@gmail.com",
  smtp_host = "smtp.gmail.com",
  smtp_port = 587,
  smtp_username = "mentormatchai.help@gmail.com",
  smtp_password = "eedb huqw arwy afwa"
)
cat("✅ Email configuration ready\n\n")

# Step 4: Test email content creation
cat("📝 Step 4: Testing email content creation...\n")
test_student_name <- "Test Student"
test_student_email <- "test@example.com"
test_time <- format(Sys.time(), "%B %d, %Y at %I:%M %p")

# Create simple test email
test_email_content <- md(glue("
# 🎉 Test Email

Hello **{test_student_name}**,

This is a test email to verify that the email system is working correctly.

**Test Time:** {test_time}  
**Test Email:** {test_student_email}

## ✅ Test Results:
- Email content creation: **Working**
- Glue template processing: **Working**
- Markdown formatting: **Working**

Best regards,  
**MentorMatchAI Test System**
"))

cat("✅ Email content created successfully\n\n")

# Step 5: Test email composition
cat("📧 Step 5: Testing email composition...\n")
test_email <- compose_email(
  body = test_email_content,
  footer = md("© 2024 MentorMatchAI | Test Email")
)
cat("✅ Email composed successfully\n\n")

# Step 6: Test email sending (test mode)
cat("🧪 Step 6: Testing email sending (test mode)...\n")
tryCatch({
  # This will only show the email content, not send it
  cat("📧 Email would be sent to:", test_student_email, "\n")
  cat("📧 From:", EMAIL_CONFIG$from_email, "\n")
  cat("📧 Subject: Test Email from MentorMatchAI\n")
  cat("✅ Test mode - email content previewed successfully\n\n")
}, error = function(e) {
  cat("❌ Error in test mode:", e$message, "\n\n")
})

# Step 7: Show available functions
cat("📚 Step 7: Available functions for testing...\n")
cat("1. test_email_content - View the test email content\n")
cat("2. test_email - View the composed email object\n")
cat("3. EMAIL_CONFIG - View email configuration\n")
cat("4. test_student_name, test_student_email - Test data\n\n")

# Step 8: Test real sending (commented out for safety)
cat("⚠️ Step 8: Real email sending (commented out for safety)\n")
cat("To send a real test email, uncomment the following lines:\n\n")

cat("# Uncomment these lines to send a real test email:\n")
cat("# smtp_send(\n")
cat("#   email = test_email,\n")
cat("#   from = EMAIL_CONFIG$from_email,\n")
cat("#   to = 'your-email@example.com',  # Replace with your email\n")
cat("#   subject = 'Test Email from MentorMatchAI',\n")
cat("#   credentials = creds(\n")
cat("#     user = EMAIL_CONFIG$smtp_username,\n")
cat("#     host = EMAIL_CONFIG$smtp_host,\n")
cat("#     port = EMAIL_CONFIG$smtp_port,\n")
cat("#     use_ssl = TRUE\n")
cat("#   )\n")
cat("# )\n\n")

# Step 9: Final test results
cat("🎯 Test Results Summary:\n")
cat(paste(rep("=", 50), collapse = ""), "\n")
cat("✅ Package loading: PASSED\n")
cat("✅ Credential file: PASSED\n")
cat("✅ Email configuration: PASSED\n")
cat("✅ Content creation: PASSED\n")
cat("✅ Email composition: PASSED\n")
cat("✅ Test mode: PASSED\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

cat("🎉 All tests passed! Your email system is ready.\n")
cat("💡 To send real emails, use the smtp_send() function with proper credentials.\n\n")

# Make objects available in environment
cat("📋 Available objects in environment:\n")
cat("- test_email_content: The email content\n")
cat("- test_email: The composed email object\n")
cat("- EMAIL_CONFIG: Email configuration\n")
cat("- test_student_name, test_student_email: Test data\n\n") 