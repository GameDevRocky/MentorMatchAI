library(sendmailR)

# Try to detect if sendmail is available
check_sendmail <- function() {
  tryCatch({
    # Try to connect to localhost:25
    con <- socketConnection(host = "localhost", port = 25, blocking = TRUE, open = "r+", timeout = 1)
    close(con)
    return(TRUE)
  }, error = function(e) {
    return(FALSE)
  })
}

# Global flag for email mode
EMAIL_MODE <- ifelse(check_sendmail(), "sendmail", "console")

send_email_to_mentor <- function(student_name, student_email, mentor_email, mentor_name, mentor_message) {
  from <- sprintf('"%s" <%s>', student_name, student_email)
  to <- sprintf('"%s" <%s>', mentor_name, mentor_email)
  subject <- sprintf("MentorMatchAI: New Mentee Match - %s", student_name)
  body <- list(
    sprintf("Hello %s,", mentor_name),
    "",
    sprintf("You have been selected as a mentor by %s.", student_name),
    "",
    "Student's message:",
    mentor_message,
    "",
    sprintf("Student's email: %s", student_email),
    "",
    "Please log in to MentorMatchAI to view more details."
  )
  
  if (EMAIL_MODE == "sendmail") {
    # Try to send real email
    tryCatch({
      sendmail(from = from, to = to, subject = subject, msg = body, control = list())
      message("✓ Email sent to mentor")
      return(TRUE)
    }, error = function(e) {
      # Fall back to console if sendmail fails
      EMAIL_MODE <<- "console"
      warning("Sendmail failed, switching to console mode")
    })
  }
  
  # Console fallback with enhanced formatting
  cat("\n\n")
  cat("📧 EMAIL TO MENTOR (Console Mode - No Mail Server):\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("From:", from, "\n")
  cat("To:", to, "\n")
  cat("Subject:", subject, "\n")
  cat(paste(rep("-", 40), collapse = ""), "\n")
  cat("Message Body:\n")
  cat(paste(body, collapse = "\n"), "\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("✅ Email logged successfully!\n")
  cat("Note: In production, this would be sent to:", to, "\n\n")
  return(TRUE)
}

send_confirmation_to_student <- function(student_name, student_email, mentor_name, timestamp) {
  from <- '"MentorMatchAI" <no-reply@mentormatchai.local>'
  to <- sprintf('"%s" <%s>', student_name, student_email)
  subject <- "MentorMatchAI: Mentor Match Confirmation"
  body <- list(
    sprintf("Congrats on finding your mentor, %s!", student_name),
    "",
    sprintf("This is confirmation that your introduction email to %s was sent at %s.", mentor_name, timestamp),
    "",
    "Good Luck!",
    "- The MentorMatchAI Team"
  )
  
  if (EMAIL_MODE == "sendmail") {
    # Try to send real email
    tryCatch({
      sendmail(from = from, to = to, subject = subject, msg = body, control = list())
      message("✓ Confirmation email sent to student")
      return(TRUE)
    }, error = function(e) {
      # Fall back to console if sendmail fails
      EMAIL_MODE <<- "console"
      warning("Sendmail failed, switching to console mode")
    })
  }
  
  # Console fallback with enhanced formatting
  cat("\n📧 EMAIL TO STUDENT (Console Mode - No Mail Server):\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("From:", from, "\n")
  cat("To:", to, "\n")
  cat("Subject:", subject, "\n")
  cat(paste(rep("-", 40), collapse = ""), "\n")
  cat("Message Body:\n")
  cat(paste(body, collapse = "\n"), "\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("✅ Confirmation email logged successfully!\n")
  cat("Note: In production, this would be sent to:", to, "\n\n")
  return(TRUE)
}

# Print status on load
if (EMAIL_MODE == "console") {
  message("📧 Email system running in console mode (no mail server detected)")
  message("   Emails will be displayed in console instead of being sent")
} else {
  message("✓ Email system ready (sendmail detected)")
}