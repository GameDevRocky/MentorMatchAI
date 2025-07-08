# Try to load required packages
tryCatch({
  library(mailR)
}, error = function(e) {
  cat("⚠️ mailR package not available. Email functionality will be limited.\n")
})

library(R6)

# Fallback if glue is not available
tryCatch({
  library(glue)
}, error = function(e) {
  # Create a simple glue function fallback
  glue <- function(x, ...) {
    eval(parse(text = paste0("sprintf('", gsub("\\{([^}]+)\\}", "%s", x), "', ", 
                            paste(gsub("\\{([^}]+)\\}", "\\1", x), collapse = ", "), ")")))
  }
})

# SMTP Configuration Class
SMTPConfig <- R6::R6Class("SMTPConfig",
  public = list(
    host = NULL,
    port = NULL,
    username = NULL,
    password = NULL,
    tls = NULL,
    
    initialize = function(host = "smtp.gmail.com", port = 587, username = "", password = "", tls = TRUE) {
      self$host <- host
      self$port <- port
      self$username <- username
      self$password <- password
      self$tls <- tls
    },
    
    is_configured = function() {
      !is.null(self$username) && self$username != "" && 
      !is.null(self$password) && self$password != ""
    }
  )
)

# Enhanced Email Service
EmailService <- R6::R6Class("EmailService",
  public = list(
    smtp_config = NULL,
    
    initialize = function(smtp_config) {
      self$smtp_config <- smtp_config
    },
    
    send_email = function(to, subject, body, html_body = NULL, from = NULL) {
      if (is.null(from)) from <- self$smtp_config$username
      
      tryCatch({
        if (self$smtp_config$is_configured()) {
          mailR::send.mail(
            from = from,
            to = to,
            subject = subject,
            body = if (is.null(html_body)) body else html_body,
            html = !is.null(html_body),
            smtp = list(
              host.name = self$smtp_config$host,
              port = self$smtp_config$port,
              user.name = self$smtp_config$username,
              passwd = self$smtp_config$password,
              ssl = self$smtp_config$tls
            ),
            authenticate = TRUE,
            send = TRUE
          )
          
          cat("✅ Email sent successfully to:", to, "\n")
          return(list(success = TRUE, message = "Email sent"))
          
        } else {
          # Fallback to console mode
          self$log_email_console(to, subject, body)
          return(list(success = FALSE, message = "SMTP not configured - logged to console"))
        }
        
      }, error = function(e) {
        cat("❌ Email sending failed:", e$message, "\n")
        self$log_email_console(to, subject, body)
        return(list(success = FALSE, message = paste("Email failed:", e$message)))
      })
    },
    
    log_email_console = function(to, subject, body) {
      cat("📧 EMAIL (Console Mode):\n")
      cat("To:", to, "\n")
      cat("Subject:", subject, "\n") 
      cat("Body:", body, "\n")
      cat("Timestamp:", as.character(Sys.time()), "\n")
      cat("----------------------------------------\n")
    }
  )
)

# Email Templates
EmailTemplates <- list(
  
  welcome_student = function(student_name, username) {
    subject <- "🎯 Welcome to MentorMatch AI!"
    body <- glue("
    Hi {student_name},

    Welcome to MentorMatch AI! We're excited to help you find the perfect mentor.

    Your account details:
    Username: {username}
    
    Next steps:
    1. Complete your profile
    2. Browse available mentors
    3. Use our AI-powered search to find matches
    4. Connect with mentors that align with your goals

    Best regards,
    The MentorMatch AI Team
    ")
    
    html_body <- glue("
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: linear-gradient(135deg, #4f8bb8 0%, #69b7d1 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;'>
        <h1 style='margin: 0; font-size: 2.5rem;'>🎯 Welcome to MentorMatch AI!</h1>
      </div>
      
      <div style='padding: 30px; background: #f8f9fa; border-radius: 0 0 10px 10px;'>
        <h2 style='color: #4f8bb8;'>Hi {student_name},</h2>
        
        <p>Welcome to MentorMatch AI! We're excited to help you find the perfect mentor.</p>
        
        <div style='background: white; padding: 20px; border-radius: 10px; margin: 20px 0;'>
          <h3 style='color: #4f8bb8; margin-top: 0;'>Your Account Details:</h3>
          <p><strong>Username:</strong> {username}</p>
        </div>
        
        <h3 style='color: #4f8bb8;'>Next Steps:</h3>
        <ol style='color: #666;'>
          <li>Complete your profile</li>
          <li>Browse available mentors</li> 
          <li>Use our AI-powered search to find matches</li>
          <li>Connect with mentors that align with your goals</li>
        </ol>
        
        <div style='text-align: center; margin: 30px 0;'>
          <a href='#' style='background: #4f8bb8; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; font-weight: bold;'>Get Started</a>
        </div>
        
        <p style='color: #999; text-align: center;'>Best regards,<br>The MentorMatch AI Team</p>
      </div>
    </div>
    ")
    
    return(list(subject = subject, body = body, html_body = html_body))
  },
  
  welcome_mentor = function(mentor_name, username) {
    subject <- "🌟 Welcome to MentorMatch AI - Thank you for becoming a mentor!"
    body <- glue("
    Hi {mentor_name},

    Thank you for joining MentorMatch AI as a mentor! Your expertise will help shape the next generation.

    Your account details:
    Username: {username}
    
    Next steps:
    1. Complete your professional profile
    2. Set your availability and preferences
    3. Review potential mentee matches
    4. Start making a difference!

    We'll notify you when students express interest in connecting with you.

    Best regards,
    The MentorMatch AI Team
    ")
    
    html_body <- glue("
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: linear-gradient(135deg, #52c3a4 0%, #20c997 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;'>
        <h1 style='margin: 0; font-size: 2.5rem;'>🌟 Welcome Mentor!</h1>
      </div>
      
      <div style='padding: 30px; background: #f8f9fa; border-radius: 0 0 10px 10px;'>
        <h2 style='color: #52c3a4;'>Hi {mentor_name},</h2>
        
        <p>Thank you for joining MentorMatch AI as a mentor! Your expertise will help shape the next generation.</p>
        
        <div style='background: white; padding: 20px; border-radius: 10px; margin: 20px 0;'>
          <h3 style='color: #52c3a4; margin-top: 0;'>Your Account Details:</h3>
          <p><strong>Username:</strong> {username}</p>
        </div>
        
        <h3 style='color: #52c3a4;'>Next Steps:</h3>
        <ol style='color: #666;'>
          <li>Complete your professional profile</li>
          <li>Set your availability and preferences</li>
          <li>Review potential mentee matches</li>
          <li>Start making a difference!</li>
        </ol>
        
        <div style='background: #e8f5e8; padding: 20px; border-radius: 10px; margin: 20px 0;'>
          <p style='margin: 0; color: #52c3a4; font-weight: bold;'>🔔 We'll notify you when students express interest in connecting with you.</p>
        </div>
        
        <div style='text-align: center; margin: 30px 0;'>
          <a href='#' style='background: #52c3a4; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; font-weight: bold;'>Complete Profile</a>
        </div>
        
        <p style='color: #999; text-align: center;'>Best regards,<br>The MentorMatch AI Team</p>
      </div>
    </div>
    ")
    
    return(list(subject = subject, body = body, html_body = html_body))
  },
  
  mentor_match_notification = function(mentor_name, student_name, student_email, student_message, compatibility_score) {
    subject <- glue("🎯 New Mentee Match: {student_name} ({compatibility_score}% compatibility)")
    body <- glue("
    Hi {mentor_name},

    Great news! A student has expressed interest in connecting with you through MentorMatch AI.

    Student Details:
    Name: {student_name}
    Email: {student_email}
    Compatibility: {compatibility_score}%

    Their message:
    '{student_message}'

    You can review their full profile and respond through the MentorMatch AI platform.

    Best regards,
    The MentorMatch AI Team
    ")
    
    html_body <- glue("
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;'>
        <h1 style='margin: 0; font-size: 2rem;'>🎯 New Mentee Match!</h1>
        <p style='margin: 10px 0 0 0; font-size: 1.2rem; opacity: 0.9;'>{compatibility_score}% Compatibility</p>
      </div>
      
      <div style='padding: 30px; background: #f8f9fa; border-radius: 0 0 10px 10px;'>
        <h2 style='color: #667eea;'>Hi {mentor_name},</h2>
        
        <p>Great news! A student has expressed interest in connecting with you through MentorMatch AI.</p>
        
        <div style='background: white; padding: 20px; border-radius: 10px; margin: 20px 0; border-left: 4px solid #667eea;'>
          <h3 style='color: #667eea; margin-top: 0;'>Student Details:</h3>
          <p><strong>Name:</strong> {student_name}</p>
          <p><strong>Email:</strong> {student_email}</p>
          <p><strong>Compatibility:</strong> <span style='background: #667eea; color: white; padding: 5px 10px; border-radius: 15px; font-weight: bold;'>{compatibility_score}%</span></p>
        </div>
        
        <div style='background: #e8f0fe; padding: 20px; border-radius: 10px; margin: 20px 0;'>
          <h4 style='color: #667eea; margin-top: 0;'>Their message:</h4>
          <p style='font-style: italic; color: #666; margin: 0;'>'{student_message}'</p>
        </div>
        
        <div style='text-align: center; margin: 30px 0;'>
          <a href='#' style='background: #667eea; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; font-weight: bold; margin: 0 10px;'>View Profile</a>
          <a href='mailto:{student_email}' style='background: #52c3a4; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; font-weight: bold; margin: 0 10px;'>Reply Directly</a>
        </div>
        
        <p style='color: #999; text-align: center;'>Best regards,<br>The MentorMatch AI Team</p>
      </div>
    </div>
    ")
    
    return(list(subject = subject, body = body, html_body = html_body))
  },
  
  match_confirmation = function(student_name, mentor_name, mentor_email) {
    subject <- "✅ Match Confirmation - Connection Request Sent!"
    body <- glue("
    Hi {student_name},

    Your connection request has been sent successfully!

    Mentor Details:
    Name: {mentor_name}
    Email: {mentor_email}

    What happens next:
    1. Your mentor will receive your message
    2. They'll review your profile
    3. Most mentors respond within 24-48 hours
    4. You'll receive a notification when they reply

    Good luck with your mentoring journey!

    Best regards,
    The MentorMatch AI Team
    ")
    
    html_body <- glue("
    <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
      <div style='background: linear-gradient(135deg, #52c3a4 0%, #20c997 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;'>
        <h1 style='margin: 0; font-size: 2rem;'>✅ Connection Request Sent!</h1>
      </div>
      
      <div style='padding: 30px; background: #f8f9fa; border-radius: 0 0 10px 10px;'>
        <h2 style='color: #52c3a4;'>Hi {student_name},</h2>
        
        <p>Your connection request has been sent successfully!</p>
        
        <div style='background: white; padding: 20px; border-radius: 10px; margin: 20px 0; border-left: 4px solid #52c3a4;'>
          <h3 style='color: #52c3a4; margin-top: 0;'>Mentor Details:</h3>
          <p><strong>Name:</strong> {mentor_name}</p>
          <p><strong>Email:</strong> {mentor_email}</p>
        </div>
        
        <h3 style='color: #52c3a4;'>What happens next:</h3>
        <ol style='color: #666;'>
          <li>Your mentor will receive your message</li>
          <li>They'll review your profile</li>
          <li>Most mentors respond within 24-48 hours</li>
          <li>You'll receive a notification when they reply</li>
        </ol>
        
        <div style='background: #e8f5e8; padding: 20px; border-radius: 10px; margin: 20px 0; text-align: center;'>
          <p style='margin: 0; color: #52c3a4; font-weight: bold; font-size: 1.1rem;'>🌟 Good luck with your mentoring journey!</p>
        </div>
        
        <p style='color: #999; text-align: center;'>Best regards,<br>The MentorMatch AI Team</p>
      </div>
    </div>
    ")
    
    return(list(subject = subject, body = body, html_body = html_body))
  },
  
  admin_notification = function(admin_name, event_type, details) {
    subject <- glue("🔔 MentorMatch AI Admin Alert: {event_type}")
    body <- glue("
    Hi {admin_name},

    Administrative notification from MentorMatch AI:

    Event: {event_type}
    Details: {details}
    Timestamp: {Sys.time()}

    Please review the admin dashboard for more information.

    Best regards,
    MentorMatch AI System
    ")
    
    return(list(subject = subject, body = body, html_body = NULL))
  }
)

# Initialize email service with default config
default_smtp <- SMTPConfig$new(
  host = "smtp.gmail.com",
  port = 587,
  username = Sys.getenv("SMTP_USERNAME", ""),
  password = Sys.getenv("SMTP_PASSWORD", ""),
  tls = TRUE
)

email_service <- EmailService$new(default_smtp)

# Convenience functions
send_welcome_email <- function(user_name, username, email, role) {
  template <- if (role == "student") {
    EmailTemplates$welcome_student(user_name, username)
  } else {
    EmailTemplates$welcome_mentor(user_name, username)
  }
  
  email_service$send_email(
    to = email,
    subject = template$subject,
    body = template$body,
    html_body = template$html_body
  )
}

send_match_notification <- function(mentor_email, mentor_name, student_name, student_email, message, score) {
  template <- EmailTemplates$mentor_match_notification(mentor_name, student_name, student_email, message, score)
  
  email_service$send_email(
    to = mentor_email,
    subject = template$subject,
    body = template$body,
    html_body = template$html_body
  )
}

send_match_confirmation <- function(student_email, student_name, mentor_name, mentor_email) {
  template <- EmailTemplates$match_confirmation(student_name, mentor_name, mentor_email)
  
  email_service$send_email(
    to = student_email,
    subject = template$subject,
    body = template$body,
    html_body = template$html_body
  )
} 