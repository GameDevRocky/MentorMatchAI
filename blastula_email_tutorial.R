# =============================================================================
# BLASTULA EMAIL TUTORIAL FOR STUDENTS
# =============================================================================
# 
# This tutorial teaches you how to design and send beautiful emails using blastula
# 
# What you'll learn:
# 1. How to install and load blastula
# 2. How to create HTML email content
# 3. How to design responsive email layouts
# 4. How to send emails with blastula
# 5. How to add dynamic content to emails
# 
# =============================================================================

# Step 1: Install and Load Required Packages
# =============================================================================

# First, install the packages if you haven't already
# install.packages("blastula")
# install.packages("glue")

# Load the packages
library(blastula)
library(glue)

cat("✅ Blastula email tutorial loaded successfully!\n\n")

# =============================================================================
# Step 2: Basic Email Configuration
# =============================================================================

# Email configuration - replace with your own email settings
EMAIL_CONFIG <- list(
  from_email = "your-email@gmail.com",  # Replace with your email
  smtp_host = "smtp.gmail.com",
  smtp_port = 587,
  smtp_username = "your-email@gmail.com",  # Replace with your email
  smtp_password = "your-app-password"      # Replace with your app password
)

cat("📧 Email configuration set up\n")
cat("⚠️  Remember to replace the email settings with your own!\n\n")

# =============================================================================
# Step 3: Create Your First Email
# =============================================================================

# Function to create a simple welcome email
create_simple_email <- function(student_name, field_of_study) {
  
  # Create HTML email content using glue()
  # This is where you design your email layout
  email_html <- glue("
    <div style='max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif;'>
      
      <!-- Header Section -->
      <div style='background-color: #4f8bb8; color: white; padding: 30px; text-align: center;'>
        <h1 style='margin: 0; font-size: 28px;'>Welcome to MentorMatchAI!</h1>
        <p style='margin: 10px 0 0 0; font-size: 16px;'>Connecting Students with Perfect Mentors</p>
      </div>
      
      <!-- Main Content -->
      <div style='padding: 30px; background-color: white;'>
        <h2 style='color: #333; font-size: 22px; margin-bottom: 20px;'>
          Hello {student_name}! 👋
        </h2>
        
        <p style='color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 20px;'>
          Welcome to MentorMatchAI! We're excited to help you find the perfect mentor 
          for your journey in <strong>{field_of_study}</strong>.
        </p>
        
        <!-- Feature Box -->
        <div style='background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;'>
          <h3 style='color: #4f8bb8; margin-top: 0;'>What's Next?</h3>
          <ul style='color: #666; line-height: 1.8;'>
            <li>Complete your profile with your goals</li>
            <li>Browse available mentors in your field</li>
            <li>Get matched with the perfect mentor</li>
            <li>Start your learning journey!</li>
          </ul>
        </div>
        
        <!-- Call to Action Button -->
        <div style='text-align: center; margin: 30px 0;'>
          <a href='https://mentormatch.app/dashboard' 
             style='background-color: #4f8bb8; color: white; padding: 12px 24px; 
                    text-decoration: none; border-radius: 5px; display: inline-block;'>
            Get Started
          </a>
        </div>
      </div>
      
      <!-- Footer -->
      <div style='background-color: #f8f9fa; padding: 20px; text-align: center; color: #666;'>
        <p style='margin: 0; font-size: 14px;'>
          © 2024 MentorMatchAI. All rights reserved.
        </p>
        <p style='margin: 5px 0 0 0; font-size: 12px;'>
          <a href='#' style='color: #4f8bb8;'>Unsubscribe</a> | 
          <a href='#' style='color: #4f8bb8;'>Privacy Policy</a>
        </p>
      </div>
      
    </div>
  ")
  
  return(email_html)
}

cat("📝 Function 'create_simple_email()' created\n")
cat("   This function creates a beautiful HTML email with:\n")
cat("   - Responsive design (max-width: 600px)\n")
cat("   - Professional header with branding\n")
cat("   - Personalized greeting\n")
cat("   - Feature highlights box\n")
cat("   - Call-to-action button\n")
cat("   - Professional footer\n\n")

# =============================================================================
# Step 4: Create a Newsletter Email with Dynamic Content
# =============================================================================

# Function to create a newsletter with dynamic mentor matches
create_newsletter_email <- function(student_name, mentor_matches) {
  
  # Create mentor cards dynamically
  mentor_cards_html <- paste0(
    sapply(seq_along(mentor_matches), function(i) {
      mentor <- mentor_matches[[i]]
      
      glue('
        <div style="border: 1px solid #ddd; border-radius: 8px; padding: 20px; margin-bottom: 20px; background-color: white;">
          
          <div style="margin-bottom: 10px;">
            <span style="background: #e7f3ff; color: #0066cc; padding: 4px 8px; border-radius: 4px; font-size: 14px;">
              {mentor$match_score}% match
            </span>
          </div>
          
          <h3 style="font-size: 18px; margin: 0 0 5px 0; color: #333;">
            {mentor$name}
          </h3>
          <p style="color: #666; margin: 0 0 15px 0; font-size: 14px;">
            {mentor$title}
          </p>
          
          <p style="margin: 10px 0; font-size: 14px;">
            <strong>Expertise:</strong> {mentor$expertise}
          </p>
          
          <p style="margin: 10px 0; font-size: 14px;">
            <strong>Rating:</strong> ⭐ {mentor$rating} ({mentor$reviews} reviews)
          </p>
          
          <div style="margin-top: 15px;">
            <a href="https://mentormatch.app/book/{i}" 
               style="background: #0066cc; color: white; padding: 8px 16px; 
                      text-decoration: none; border-radius: 4px; font-size: 14px;">
              Book Session
            </a>
          </div>
          
        </div>')
    }), collapse = ''
  )
  
  # Create the full newsletter HTML
  newsletter_html <- glue("
    <div style='max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif;'>
      
      <!-- Header -->
      <div style='background: linear-gradient(135deg, #4f8bb8 0%, #2c5aa0 100%); color: white; padding: 30px; text-align: center;'>
        <h1 style='margin: 0; font-size: 28px;'>MentorMatchAI Newsletter</h1>
        <p style='margin: 10px 0 0 0; font-size: 16px;'>Your Weekly Mentor Updates</p>
      </div>
      
      <!-- Main Content -->
      <div style='padding: 30px; background-color: white;'>
        <h2 style='color: #333; font-size: 22px; margin-bottom: 20px;'>
          Hi {student_name}! 🎉
        </h2>
        
        <p style='color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 30px;'>
          We found {length(mentor_matches)} amazing mentors for you this week!
        </p>
        
        <!-- Mentor Matches Section -->
        <h3 style='color: #333; font-size: 18px; margin-bottom: 20px;'>
          Your Top Matches
        </h3>
        
        {mentor_cards_html}
        
        <!-- Next Steps -->
        <div style='background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 30px 0;'>
          <h3 style='color: #4f8bb8; margin-top: 0;'>What's Next?</h3>
          <ol style='color: #666; line-height: 1.8; margin: 0; padding-left: 20px;'>
            <li>Review your mentor matches above</li>
            <li>Book a 30-minute intro call with 1-3 mentors</li>
            <li>Choose the mentor that feels right for you</li>
            <li>Start your learning journey!</li>
          </ol>
        </div>
      </div>
      
      <!-- Footer -->
      <div style='background-color: #f8f9fa; padding: 20px; text-align: center; color: #666;'>
        <p style='margin: 0; font-size: 14px;'>
          Questions? Email us at support@mentormatch.app
        </p>
        <p style='margin: 5px 0 0 0; font-size: 12px;'>
          © 2024 MentorMatchAI. All rights reserved.
        </p>
      </div>
      
    </div>
  ")
  
  return(newsletter_html)
}

cat("📝 Function 'create_newsletter_email()' created\n")
cat("   This function creates a dynamic newsletter with:\n")
cat("   - Gradient header design\n")
cat("   - Dynamic mentor cards based on data\n")
cat("   - Personalized content using glue()\n")
cat("   - Professional styling and layout\n\n")

# =============================================================================
# Step 5: Send Email Function
# =============================================================================

# Function to send emails using blastula
send_email_with_blastula <- function(to_email, subject, html_content, test_mode = TRUE) {
  
  cat("📧 Preparing to send email...\n")
  cat("To:", to_email, "\n")
  cat("Subject:", subject, "\n")
  
  if (test_mode) {
    # Test mode - just show the email content
    cat("\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat("TEST MODE - Email content preview:\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat(html_content, "\n")
    cat(paste(rep("=", 60), collapse = ""), "\n")
    cat("✅ Email content created successfully!\n")
    cat("💡 To send real emails, set test_mode = FALSE and configure SMTP\n\n")
    return(TRUE)
  }
  
  # Real email sending mode
  if (EMAIL_CONFIG$smtp_username == "your-email@gmail.com") {
    cat("❌ Please configure your email settings first!\n")
    cat("   Update EMAIL_CONFIG with your real email credentials\n\n")
    return(FALSE)
  }
  
  tryCatch({
    # Create email using blastula
    email <- compose_email(
      body = md(html_content)
    )
    
    # Send email using blastula's smtp_send
    smtp_send(
      email,
      to = to_email,
      from = EMAIL_CONFIG$from_email,
      subject = subject,
      credentials = creds(
        user = EMAIL_CONFIG$smtp_username,
        host = EMAIL_CONFIG$smtp_host,
        port = EMAIL_CONFIG$smtp_port,
        use_ssl = TRUE
      )
    )
    
    cat("✅ Email sent successfully!\n\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("❌ Error sending email:", e$message, "\n")
    cat("💡 Make sure your SMTP settings are correct\n\n")
    return(FALSE)
  })
}

cat("📝 Function 'send_email_with_blastula()' created\n")
cat("   This function handles email sending with:\n")
cat("   - Test mode for previewing emails\n")
cat("   - Real email sending with SMTP\n")
cat("   - Error handling and user feedback\n\n")

# =============================================================================
# Step 6: Example Usage and Practice
# =============================================================================

# Example 1: Send a simple welcome email
example_simple_email <- function() {
  cat("🎯 Example 1: Simple Welcome Email\n")
  cat(paste(rep("=", 40), collapse = ""), "\n")
  
  # Create email content
  email_html <- create_simple_email("Sarah", "Data Science")
  
  # Send email (in test mode)
  send_email_with_blastula(
    to_email = "sarah@example.com",
    subject = "Welcome to MentorMatchAI! 🎉",
    html_content = email_html,
    test_mode = TRUE
  )
}

# Example 2: Send a newsletter with mentor matches
example_newsletter_email <- function() {
  cat("🎯 Example 2: Newsletter with Mentor Matches\n")
  cat(paste(rep("=", 40), collapse = ""), "\n")
  
  # Sample mentor data
  mentor_matches <- list(
    list(
      name = "Dr. Sarah Chen",
      title = "Senior Data Scientist",
      expertise = "Machine Learning, Python, R",
      match_score = 95,
      rating = "4.9",
      reviews = "127"
    ),
    list(
      name = "Prof. Michael Rodriguez",
      title = "AI Research Lead",
      expertise = "Deep Learning, Computer Vision",
      match_score = 88,
      rating = "4.8",
      reviews = "89"
    ),
    list(
      name = "Alex Johnson",
      title = "Data Engineering Manager",
      expertise = "Big Data, Spark, SQL",
      match_score = 82,
      rating = "4.7",
      reviews = "156"
    )
  )
  
  # Create newsletter content
  email_html <- create_newsletter_email("John", mentor_matches)
  
  # Send email (in test mode)
  send_email_with_blastula(
    to_email = "john@example.com",
    subject = "🎯 Your Perfect Mentor Matches Are Here!",
    html_content = email_html,
    test_mode = TRUE
  )
}

# =============================================================================
# Step 7: Student Practice Functions
# =============================================================================

# Function for students to practice creating their own emails
student_practice_email <- function(student_name, field_of_study, personal_message) {
  
  # Students can customize this template using paste() for simplicity
  custom_email_html <- paste0("
    <div style='max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif;'>
      
      <!-- Custom Header -->
      <div style='background-color: #6c5ce7; color: white; padding: 30px; text-align: center;'>
        <h1 style='margin: 0; font-size: 28px;'>Welcome to Our Platform!</h1>
        <p style='margin: 10px 0 0 0; font-size: 16px;'>Your Learning Journey Starts Here</p>
      </div>
      
      <!-- Custom Content -->
      <div style='padding: 30px; background-color: white;'>
        <h2 style='color: #333; font-size: 22px; margin-bottom: 20px;'>
          Hello ", student_name, "! 🚀
        </h2>
        
        <p style='color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 20px;'>
          Welcome to our platform! We're excited to help you learn ", field_of_study, ".
        </p>
        
        <!-- Student's Custom Message -->
        <div style='background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;'>
          <h3 style='color: #6c5ce7; margin-top: 0;'>Your Message:</h3>
          <p style='color: #666; font-style: italic; margin: 0;'>
            \"", personal_message, "\"
          </p>
        </div>
        
        <!-- Custom Call to Action -->
        <div style='text-align: center; margin: 30px 0;'>
          <a href='#' style='background-color: #6c5ce7; color: white; padding: 12px 24px; 
                           text-decoration: none; border-radius: 5px; display: inline-block;'>
            Start Learning
          </a>
        </div>
      </div>
      
      <!-- Custom Footer -->
      <div style='background-color: #f8f9fa; padding: 20px; text-align: center; color: #666;'>
        <p style='margin: 0; font-size: 14px;'>
          Made with ❤️ by ", student_name, "
        </p>
      </div>
      
    </div>
  ")
  
  return(custom_email_html)
}

cat("📝 Function 'student_practice_email()' created\n")
cat("   Students can use this to practice creating custom emails\n\n")

# =============================================================================
# Step 8: Documentation and Tips
# =============================================================================

print_email_tips <- function() {
  cat("💡 EMAIL DESIGN TIPS FOR STUDENTS:\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  cat("1. Keep emails mobile-friendly (max-width: 600px)\n")
  cat("2. Use inline CSS for email client compatibility\n")
  cat("3. Test your emails in different email clients\n")
  cat("4. Use clear call-to-action buttons\n")
  cat("5. Keep content concise and scannable\n")
  cat("6. Use professional colors and fonts\n")
  cat("7. Always include an unsubscribe link\n")
  cat("8. Test your emails before sending to real users\n\n")
  
  cat("🔧 TECHNICAL TIPS:\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  cat("1. Use glue() for dynamic content\n")
  cat("2. Test with blastula's preview functions\n")
  cat("3. Configure SMTP settings for real sending\n")
  cat("4. Handle errors gracefully\n")
  cat("5. Use markdown for complex layouts\n\n")
}

# =============================================================================
# Step 9: Run Examples
# =============================================================================

cat("🚀 Running email examples...\n\n")

# Run the examples
example_simple_email()
cat("\n")
example_newsletter_email()
cat("\n")

# Print tips
print_email_tips()

cat("✅ Blastula email tutorial completed!\n")
cat("🎓 Students can now practice creating and sending beautiful emails!\n\n")

cat("📚 NEXT STEPS FOR STUDENTS:\n")
cat("1. Try the student_practice_email() function\n")
cat("2. Customize the email templates\n")
cat("3. Configure real SMTP settings\n")
cat("4. Send test emails to yourself\n")
cat("5. Experiment with different designs\n\n") 