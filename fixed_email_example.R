# =============================================================================
# FIXED EMAIL EXAMPLE - Using Existing Credentials
# =============================================================================
# 
# This example shows how to send a professional application confirmation email
# using the existing MentorMatchAI credentials
# 
# =============================================================================

# Load the libraries
library(blastula)
library(glue)

# Set up email credentials
EMAIL_CONFIG <- list(
  from_email = "mentormatchai.help@gmail.com",
  smtp_host = "smtp.gmail.com",
  smtp_port = 587,
  smtp_username = "mentormatchai.help@gmail.com",
  smtp_password = "eedb huqw arwy afwa"  # From gmail_credss file
)

cat("✅ Email configuration set up\n")

# Sample student data (this would come from your form/database)
student_name <- "Alex Johnson"
student_email <- "alex.johnson@student.edu"
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
send_application_email <- function(test_mode = TRUE) {
  
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
    # Send the email
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

# Function to create a more beautiful HTML version
create_beautiful_application_email <- function(student_name, student_email, selected_fields, mentorship_type) {
  
  # Format the submission time outside of glue
  submission_time <- format(Sys.time(), "%B %d, %Y at %I:%M %p")
  
  # Create a more visually appealing HTML email
  html_content <- glue("
    <div style='max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif;'>
      
      <!-- Header -->
      <div style='background: linear-gradient(135deg, #4f8bb8 0%, #2c5aa0 100%); color: white; padding: 30px; text-align: center;'>
        <h1 style='margin: 0; font-size: 28px;'>🎉 Application Received!</h1>
        <p style='margin: 10px 0 0 0; font-size: 16px;'>Welcome to MentorMatchAI</p>
      </div>
      
      <!-- Main Content -->
      <div style='padding: 30px; background-color: white;'>
        <h2 style='color: #333; font-size: 22px; margin-bottom: 20px;'>
          Hello {student_name}! 👋
        </h2>
        
        <p style='color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 20px;'>
          Thank you for submitting your mentorship application to <strong>MentorMatchAI</strong>! 
          We're excited to help you connect with the perfect mentor.
        </p>
        
        <!-- Submission Details -->
        <div style='background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;'>
          <h3 style='color: #4f8bb8; margin-top: 0;'>📋 Your Submission Details</h3>
          <p style='margin: 10px 0;'><strong>Email:</strong> {student_email}</p>
          <p style='margin: 10px 0;'><strong>Areas of Interest:</strong> {paste(selected_fields, collapse = ", ")}</p>
          <p style='margin: 10px 0;'><strong>Mentorship Type:</strong> {mentorship_type}</p>
          <p style='margin: 10px 0;'><strong>Submitted:</strong> {submission_time}</p>
        </div>
        
        <!-- Next Steps -->
        <div style='background-color: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0;'>
          <h3 style='color: #0066cc; margin-top: 0;'>🚀 What Happens Next?</h3>
          <ol style='color: #333; line-height: 1.8; margin: 0; padding-left: 20px;'>
            <li><strong>Review Process</strong> - Our AI system is analyzing your profile (24-48 hours)</li>
            <li><strong>Mentor Matching</strong> - We'll identify the top 3 mentors for your needs</li>
            <li><strong>Introduction Email</strong> - You'll receive mentor profiles and introduction instructions</li>
            <li><strong>First Meeting</strong> - Schedule your initial consultation within 1 week</li>
          </ol>
        </div>
        
        <!-- Stats -->
        <div style='background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;'>
          <h3 style='color: #4f8bb8; margin-top: 0;'>📊 Quick Stats</h3>
          <div style='display: flex; justify-content: space-between; margin: 15px 0;'>
            <div style='text-align: center;'>
              <div style='font-size: 24px; font-weight: bold; color: #4f8bb8;'>94%</div>
              <div style='font-size: 12px; color: #666;'>Match Satisfaction</div>
            </div>
            <div style='text-align: center;'>
              <div style='font-size: 24px; font-weight: bold; color: #4f8bb8;'>36h</div>
              <div style='font-size: 12px; color: #666;'>Avg Response Time</div>
            </div>
            <div style='text-align: center;'>
              <div style='font-size: 24px; font-weight: bold; color: #4f8bb8;'>127</div>
              <div style='font-size: 12px; color: #666;'>Active Mentors</div>
            </div>
          </div>
        </div>
        
        <!-- Call to Action -->
        <div style='text-align: center; margin: 30px 0;'>
          <a href='https://mentormatchai.com/dashboard' 
             style='background-color: #4f8bb8; color: white; padding: 12px 24px; 
                    text-decoration: none; border-radius: 5px; display: inline-block;'>
            View Your Dashboard
          </a>
        </div>
      </div>
      
      <!-- Footer -->
      <div style='background-color: #f8f9fa; padding: 20px; text-align: center; color: #666;'>
        <p style='margin: 0; font-size: 14px;'>
          Questions? Reply to this email or visit our 
          <a href='https://mentormatchai.com/faq' style='color: #4f8bb8;'>FAQ page</a>
        </p>
        <p style='margin: 5px 0 0 0; font-size: 12px;'>
          © 2024 MentorMatchAI. All rights reserved. | 
          <a href='https://mentormatchai.com/unsubscribe' style='color: #4f8bb8;'>Unsubscribe</a>
        </p>
      </div>
      
    </div>
  ")
  
  return(html_content)
}

# Function to send the beautiful HTML email
send_beautiful_application_email <- function(test_mode = TRUE) {
  
  cat("📧 Preparing to send beautiful application confirmation email...\n")
  cat("To:", student_email, "\n")
  cat("Subject: Welcome to MentorMatchAI, {student_name}! 🎓\n")
  
  # Create the beautiful HTML email
  html_content <- create_beautiful_application_email(
    student_name, student_email, selected_fields, mentorship_type
  )
  
  if (test_mode) {
    # Test mode - just show the email content
    cat("\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat("TEST MODE - Beautiful HTML email preview:\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat(html_content, "\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat("✅ Beautiful email content created successfully!\n")
    cat("💡 To send real emails, set test_mode = FALSE\n\n")
    return(TRUE)
  }
  
  # Real email sending mode
  tryCatch({
    # Create email using blastula
    email <- compose_email(
      body = md(html_content)
    )
    
    # Send the email
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
    
    cat("✅ Beautiful email sent successfully!\n")
    cat("📧 Check the recipient's email: {student_email}\n\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("❌ Error sending email:", e$message, "\n")
    cat("💡 Make sure your credentials are properly configured\n\n")
    return(FALSE)
  })
}

# Run the examples
cat("🚀 Running email examples...\n\n")

# Example 1: Original markdown email
cat("📝 Example 1: Markdown Email\n")
cat(paste(rep("=", 40), collapse = ""), "\n")
send_application_email(test_mode = TRUE)

cat("\n")

# Example 2: Beautiful HTML email
cat("📝 Example 2: Beautiful HTML Email\n")
cat(paste(rep("=", 40), collapse = ""), "\n")
send_beautiful_application_email(test_mode = TRUE)

cat("\n")

cat("✅ Email examples completed!\n")
cat("🎓 Students can now practice with both markdown and HTML email styles!\n\n")

cat("📚 Available Functions:\n")
cat("1. send_application_email(test_mode = TRUE/FALSE)\n")
cat("2. send_beautiful_application_email(test_mode = TRUE/FALSE)\n")
cat("3. create_beautiful_application_email() - Create custom HTML emails\n\n") 