# =============================================================================
# STUDENT EMAIL SETUP - Use Existing Credentials
# =============================================================================
# 
# This script allows students to use the existing email credentials
# without having to set up their own Gmail account
# 
# =============================================================================

# Load required packages
library(blastula)
library(glue)

cat("📧 Setting up email system with existing credentials...\n")

# Load the existing credentials
tryCatch({
  # Try to load the credentials file
  if (file.exists("gmail_credss")) {
    creds <- readRDS("gmail_credss")
    cat("✅ Successfully loaded existing credentials!\n")
    cat("📧 Email: mentormatchai.help@gmail.com\n")
    cat("🔐 Using existing app password\n\n")
  } else if (file.exists("gmail_creds")) {
    creds <- readRDS("gmail_creds")
    cat("✅ Successfully loaded existing credentials!\n")
    cat("📧 Email: mentormatchai.help@gmail.com\n")
    cat("⚠️  Note: Password field is empty, you'll need to add it manually\n\n")
  } else {
    cat("❌ No credential files found!\n")
    cat("💡 Ask your instructor for the credential files\n\n")
    return(FALSE)
  }
  
  # Update the EMAIL_CONFIG in the tutorial
  EMAIL_CONFIG <<- list(
    from_email = "mentormatchai.help@gmail.com",
    smtp_host = "smtp.gmail.com",
    smtp_port = 587,
    smtp_username = "mentormatchai.help@gmail.com",
    smtp_password = creds$password %||% "eedb huqw arwy afwa"  # Use existing password
  )
  
  cat("✅ Email configuration updated!\n")
  cat("🚀 You can now send real emails using the tutorial\n\n")
  
  return(TRUE)
  
}, error = function(e) {
  cat("❌ Error loading credentials:", e$message, "\n")
  cat("💡 Make sure the credential files are in the same directory\n\n")
  return(FALSE)
})

# Function to test the email setup
test_email_setup <- function() {
  cat("🧪 Testing email setup...\n")
  
  # Create a simple test email
  test_html <- glue("
    <div style='max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif;'>
      <div style='background-color: #4f8bb8; color: white; padding: 30px; text-align: center;'>
        <h1 style='margin: 0; font-size: 28px;'>Email Setup Test</h1>
        <p style='margin: 10px 0 0 0; font-size: 16px;'>Testing blastula email functionality</p>
      </div>
      <div style='padding: 30px; background-color: white;'>
        <h2 style='color: #333; font-size: 22px; margin-bottom: 20px;'>
          Hello Student! 👋
        </h2>
        <p style='color: #666; font-size: 16px; line-height: 1.6;'>
          This is a test email to verify that your email setup is working correctly.
        </p>
        <div style='text-align: center; margin: 30px 0;'>
          <a href='#' style='background-color: #4f8bb8; color: white; padding: 12px 24px; 
                           text-decoration: none; border-radius: 5px; display: inline-block;'>
            Test Button
          </a>
        </div>
      </div>
      <div style='background-color: #f8f9fa; padding: 20px; text-align: center; color: #666;'>
        <p style='margin: 0; font-size: 14px;'>
          © 2024 MentorMatchAI. Test email.
        </p>
      </div>
    </div>
  ")
  
  # Try to send a test email
  tryCatch({
    # Create email using blastula
    email <- compose_email(
      body = md(test_html)
    )
    
    # Send test email
    smtp_send(
      email,
      to = "mentormatchai.help@gmail.com",  # Send to yourself for testing
      from = EMAIL_CONFIG$from_email,
      subject = "🧪 Email Setup Test - Student Tutorial",
      credentials = creds
    )
    
    cat("✅ Test email sent successfully!\n")
    cat("📧 Check your email: mentormatchai.help@gmail.com\n")
    cat("🎉 Your email setup is working perfectly!\n\n")
    
  }, error = function(e) {
    cat("❌ Test email failed:", e$message, "\n")
    cat("💡 You can still use test_mode = TRUE in the tutorial\n\n")
  })
}

# Function to show available functions
show_available_functions <- function() {
  cat("📚 Available Functions for Students:\n")
  cat("="*50 + "\n")
  cat("1. test_email_setup() - Test your email configuration\n")
  cat("2. source('blastula_email_tutorial.R') - Load the main tutorial\n")
  cat("3. create_simple_email() - Create welcome emails\n")
  cat("4. create_newsletter_email() - Create newsletters\n")
  cat("5. send_email_with_blastula() - Send emails\n")
  cat("6. student_practice_email() - Practice custom emails\n\n")
  
  cat("🚀 Quick Start:\n")
  cat("1. Run this setup script first\n")
  cat("2. Load the tutorial: source('blastula_email_tutorial.R')\n")
  cat("3. Try the examples in the tutorial\n")
  cat("4. Test real sending with test_email_setup()\n\n")
}

# Show available functions
show_available_functions()

cat("✅ Student email setup completed!\n")
cat("🎓 You're ready to start learning email design with blastula!\n\n") 