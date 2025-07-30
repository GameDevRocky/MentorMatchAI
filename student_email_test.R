# =============================================================================
# STUDENT EMAIL TEST - Using gmail_credss Credentials
# =============================================================================

# Load the libraries
library(blastula)
library(glue)
library(jsonlite)

# Set up email credentials using the existing gmail_credss file
EMAIL_CONFIG <- list(
  from_email = "mentormatchai.help@gmail.com",
  smtp_host = "smtp.gmail.com",
  smtp_port = 587,
  smtp_username = "mentormatchai.help@gmail.com",
  smtp_password = "eedb huqw arwy afwa"  # From gmail_credss file
)

cat("✅ Email configuration set up using gmail_credss credentials\n")

# Sample student data (this would come from your form/database)
student_name <- "Alex Johnson"
student_email <- "nydjeem1@gmail.com"
submission_time <- format(Sys.time(), "%B %d, %Y at %I:%M %p")
selected_fields <- c("Data Science", "Machine Learning", "Python")
mentorship_type <- "Technical Skills Development"

# Create email content using blastula's md() with glue
email_content <- md(glue::glue('
# 🎉 Application Received!

Hello **{student_name}**,

Thank you for submitting your mentorship application to **MentorMatchAI**! We\'re excited to help you connect with the perfect mentor.

## 📋 Your Submission Details:

**Submitted on:** {submission_time}  
**Your Email:** {student_email}  
**Areas of Interest:** {paste(selected_fields, collapse = ", ")}  
**Mentorship Type:** {mentorship_type}

## 🚀 What Happens Next?

1. **Review Process** - Our AI system is analyzing your profile (24-48 hours)
2. **Mentor Matching** - We\'ll identify the top 3 mentors for your needs  
3. **Introduction Email** - You\'ll receive mentor profiles and introduction instructions
4. **First Meeting** - Schedule your initial consultation within 1 week

## 📊 Quick Stats:
- Average match satisfaction: **94%**
- Typical response time: **36 hours**
- Active mentors in your field: **127**

---

*Questions? Reply to this email or visit our [FAQ page](https://mentormatchai.com/faq)*

Best regards,  
**The MentorMatchAI Team**

You\'re receiving this because you submitted a mentorship application. [Unsubscribe](https://mentormatchai.com/unsubscribe)
'))

# Create the email
email <- compose_email(
  body = email_content,
  footer = md("© 2024 MentorMatchAI | Connecting Students with Mentors")
)

# Function to send email with proper error handling
send_test_email <- function(test_mode = TRUE) {
  
  cat("📧 Preparing to send application confirmation email...\n")
  cat("To:", student_email, "\n")
  cat("Subject: Welcome to MentorMatchAI, {student_name}! 🎓\n")
  
  if (test_mode) {
    # Test mode - just show the email content
    cat("\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat("TEST MODE - Email content preview:\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat(as.character(email_content), "\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat("✅ Email content created successfully!\n")
    cat("💡 To send real emails, set test_mode = FALSE\n\n")
    return(TRUE)
  }
  
  # Real email sending mode
  tryCatch({
    # Send the email using blastula's smtp_send
    smtp_send(
      email = email,
      from = EMAIL_CONFIG$from_email,
      to = student_email,
      subject = glue("Welcome to MentorMatchAI, {student_name}! 🎓"),
      credentials = creds(
        user = EMAIL_CONFIG$smtp_username,
        host = EMAIL_CONFIG$smtp_host,
        port = EMAIL_CONFIG$smtp_port,
        use_ssl = TRUE
      )
    )
    
    cat("✅ Email sent successfully!\n")
    cat("📧 Check the recipient's email: {student_email}\n\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("❌ Error sending email:", e$message, "\n")
    cat("💡 Make sure your credentials are properly configured\n\n")
    return(FALSE)
  })
}

# Test the email (safe mode)
cat("🚀 Testing email functionality...\n\n")
send_test_email(test_mode = TRUE)

cat("📚 Available Functions:\n")
cat("1. send_test_email(test_mode = TRUE) - Preview email\n")
cat("2. send_test_email(test_mode = FALSE) - Send real email\n")
cat("3. email_content - View the email content\n")
cat("4. email - View the composed email object\n\n")

cat("✅ Email test completed!\n")
cat("🎓 You can now send real emails by setting test_mode = FALSE\n\n") 