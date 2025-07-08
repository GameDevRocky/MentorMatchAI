library(shiny)
library(bslib)
library(DBI)
library(RSQLite)
library(text2vec)
library(Matrix)

# Source the mentor recommender functions
source("mentor_recommender.R")

# Use the existing database name from original app
DB_NAME <- "mentormatch_enhanced.sqlite"

# Simple UI
ui <- page_navbar(
  title = "MentorMatch Simple",
  theme = bs_theme(version = 5, primary = "#4f8bb8"),
  
  nav_panel(
    title = "Home",
    
    div(
      style = "text-align: center; padding: 40px;",
      h1("Welcome to MentorMatch"),
      p("Connect with the perfect mentor using AI-powered matching", 
        style = "font-size: 1.2rem; margin-bottom: 30px;"),
      
      div(
        actionButton("show_student_form", "I'm a Student", 
                     class = "btn-primary btn-lg", 
                     style = "margin: 10px;"),
        actionButton("show_mentor_form", "I'm a Mentor", 
                     class = "btn-success btn-lg",
                     style = "margin: 10px;")
      )
    ),
    
    hr(),
    
    # Results will appear here
    uiOutput("results_section")
  ),
  
  nav_panel(
    title = "About",
    div(
      style = "padding: 20px; max-width: 800px; margin: 0 auto;",
      h3("About MentorMatch"),
      p("This application uses semantic text analysis to match students with appropriate mentors."),
      h4("How it works:"),
      tags$ol(
        tags$li("Students and mentors fill out detailed questionnaires"),
        tags$li("The system analyzes responses using text embeddings"),
        tags$li("Cosine similarity finds the best matches"),
        tags$li("Students can connect with their top matches")
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  
  # Reactive values
  student_data <- reactiveValues()
  matches <- reactiveVal(NULL)
  selected_mentor <- reactiveVal(NULL)
  embedding_system <- reactiveVal(NULL)
  
  # Initialize embedding system
  observe({
    con <- dbConnect(RSQLite::SQLite(), DB_NAME)
    
    # Count mentors in existing mentor_profiles table
    mentor_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM mentor_profiles WHERE active = 1")$n
    
    if (mentor_count >= 3) {
      tryCatch({
        embedding_system(default_embedding_system(con))
        message("✓ Semantic recommendation system initialized")
      }, error = function(e) {
        message("⚠ Could not initialize semantic system: ", e$message)
      })
    } else {
      message("⚠ Not enough mentors for semantic matching (", mentor_count, "/3)")
    }
    
    dbDisconnect(con)
  })
  
  # Show student form with ALL original questions
  observeEvent(input$show_student_form, {
    showModal(modalDialog(
      title = "Student Questionnaire",
      size = "l",
      
      fluidRow(
        column(6,
               h5("Personal Information"),
               textInput("student_name", "Full Name", placeholder = "Alex Johnson"),
               textInput("student_email", "Email Address", placeholder = "alex@university.edu"),
               
               selectInput("student_major", "Primary Academic Interest",
                           choices = list(
                             "STEM" = c("Computer Science", "Engineering", "Mathematics", 
                                        "Physics", "Biology", "Chemistry"),
                             "Business & Economics" = c("Business Administration", "Economics", 
                                                        "Finance", "Marketing", "Entrepreneurship"),
                             "Social Sciences" = c("Psychology", "Sociology", "Political Science", 
                                                   "International Relations"),
                             "Humanities" = c("English Literature", "History", "Philosophy", 
                                              "Languages", "Art"),
                             "Health & Medicine" = c("Pre-Med", "Nursing", "Public Health", 
                                                     "Biomedical Sciences"),
                             "Other" = c("Law", "Education", "Communications", 
                                         "Environmental Studies", "Other")
                           ),
                           selected = NULL),
               
               selectInput("student_level", "Academic Level",
                           choices = c("High School Student", "Undergraduate", 
                                       "Graduate Student", "Recent Graduate", "Career Changer"),
                           selected = NULL)
        ),
        
        column(6,
               h5("Career Goals"),
               selectInput("career_interest", "Target Industry",
                           choices = c("Technology & Software", "Healthcare & Medicine", 
                                       "Business & Finance", "Education & Academia", 
                                       "Government & Public Policy", "Non-profit & Social Impact",
                                       "Creative & Media", "Engineering & Manufacturing", 
                                       "Research & Development", "Other"),
                           selected = NULL),
               
               selectInput("career_stage", "Career Goal Timeline",
                           choices = c("Exploring different paths", "Preparing for internships", 
                                       "Job searching", "Planning graduate school", 
                                       "Changing career direction", "Starting my own business"),
                           selected = NULL),
               
               h5("Mentorship Preferences"),
               checkboxGroupInput("mentorship_type", "What kind of guidance do you need?",
                                  choices = c("Career planning & strategy" = "career_planning",
                                              "Industry insights & networking" = "networking",
                                              "Skill development & learning" = "skills",
                                              "Job search & interview prep" = "job_prep",
                                              "Graduate school guidance" = "grad_school",
                                              "Personal development & confidence" = "personal_dev"),
                                  selected = NULL)
        )
      ),
      
      textAreaInput("biggest_challenge", "What's your biggest current challenge or goal?",
                    height = "100px",
                    placeholder = "e.g., 'I'm struggling to choose between different career paths in tech...'"),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("submit_student", "Find My Mentor!", class = "btn-primary")
      )
    ))
  })
  
  # Show mentor form with ALL original questions
  observeEvent(input$show_mentor_form, {
    showModal(modalDialog(
      title = "Mentor Registration",
      size = "l",
      
      fluidRow(
        column(6,
               h5("Professional Information"),
               textInput("mentor_name", "Full Name", placeholder = "Dr. Jane Smith"),
               textInput("mentor_email", "Email Address", placeholder = "jane@company.com"),
               textInput("mentor_title", "Current Position", 
                         placeholder = "Senior Data Scientist at TechCorp"),
               
               selectInput("mentor_industry", "Primary Industry",
                           choices = c("Technology & Software", "Healthcare & Medicine", 
                                       "Business & Finance", "Education & Academia", 
                                       "Government & Public Policy", "Non-profit & Social Impact",
                                       "Creative & Media", "Engineering & Manufacturing", 
                                       "Research & Development", "Other"),
                           selected = NULL),
               
               selectInput("mentor_experience", "Years of Experience",
                           choices = c("3-5 years", "5-10 years", "10-15 years", "15+ years"),
                           selected = NULL)
        ),
        
        column(6,
               h5("Expertise & Mentoring"),
               checkboxGroupInput("mentor_expertise", "Areas of Expertise",
                                  choices = c("Technical skills & programming" = "technical",
                                              "Career strategy & planning" = "career_strategy",
                                              "Leadership & management" = "leadership",
                                              "Entrepreneurship & startups" = "entrepreneurship",
                                              "Research & academia" = "research",
                                              "Industry networking" = "networking",
                                              "Graduate school prep" = "grad_prep",
                                              "Interview & job search" = "interview_prep"),
                                  selected = NULL),
               
               checkboxGroupInput("mentor_willing", "I'm willing to help with:",
                                  choices = c("One-on-one mentoring sessions" = "one_on_one",
                                              "Resume & portfolio reviews" = "resume_review",
                                              "Mock interviews & prep" = "interview_practice",
                                              "Industry introductions" = "introductions",
                                              "Career advice & planning" = "career_advice",
                                              "Skill development guidance" = "skill_guidance"),
                                  selected = NULL),
               
               selectInput("communication_pref", "Preferred Communication",
                           choices = c("Email exchanges", "Video calls (30-60 min)", 
                                       "Phone calls", "In-person meetings", "Flexible - any method"),
                           selected = NULL)
        )
      ),
      
      textAreaInput("mentor_bio", "Professional Bio & Mentoring Philosophy",
                    height = "100px",
                    placeholder = "Tell potential mentees about your background and what you can offer..."),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("submit_mentor", "Join as Mentor", class = "btn-success")
      )
    ))
  })
  
  # Handle student submission
  observeEvent(input$submit_student, {
    req(input$student_name, input$student_email, input$student_major, input$career_interest)
    
    # Store student data with NULL safety
    student_data$name <- input$student_name
    student_data$email <- input$student_email
    student_data$major <- input$student_major
    student_data$career_interest <- input$career_interest
    student_data$career_stage <- if(is.null(input$career_stage)) "Not specified" else input$career_stage
    student_data$mentorship_type <- if(is.null(input$mentorship_type)) "General guidance" else paste(input$mentorship_type, collapse = ", ")
    student_data$challenge <- if(is.null(input$biggest_challenge)) "Not specified" else input$biggest_challenge
    student_data$level <- if(is.null(input$student_level)) "Not specified" else input$student_level
    
    # Save to existing students_enhanced table
    con <- dbConnect(RSQLite::SQLite(), DB_NAME)
    
    dbExecute(con, 
              "INSERT INTO students_enhanced (name, email, field_of_study, career_interest, 
                                     mentorship_goals, education_level, challenges, 
                                     communication_style, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))",
              params = list(
                student_data$name,
                student_data$email,
                student_data$major,
                student_data$career_interest,
                student_data$mentorship_type,
                student_data$level,
                student_data$challenge,
                "Email"  # Default communication style
              ))
    
    student_id <- dbGetQuery(con, "SELECT last_insert_rowid() as id")$id
    student_data$id <- student_id
    
    removeModal()
    
    # Check if we have enough mentors
    mentor_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM mentor_profiles WHERE active = 1")$n
    
    if (mentor_count >= 3 && !is.null(embedding_system())) {
      # Use semantic matching
      student_answers <- list(
        major = student_data$major,
        career = student_data$career_interest,
        mentorship = student_data$mentorship_type,
        challenge = student_data$challenge,
        level = student_data$level,
        stage = student_data$career_stage
      )
      
      recommendations <- get_mentor_recommendations(student_answers, embedding_system(), top_k = 3)
      matches(recommendations)
      
      # Show matches in modal
      show_mentor_matches_modal()
      
    } else if (mentor_count > 0) {
      # Simple fallback - get random mentors
      mentors <- dbGetQuery(con, "SELECT * FROM mentor_profiles WHERE active = 1 LIMIT 3")
      simple_matches <- lapply(seq_len(nrow(mentors)), function(i) {
        mentor <- as.list(mentors[i, ])
        mentor$score <- 0.75 + runif(1, -0.1, 0.1)
        mentor
      })
      matches(simple_matches)
      
      # Show matches in modal
      show_mentor_matches_modal()
      
    } else {
      showNotification("No mentors available yet. Please check back later!", type = "warning", duration = 5)
    }
    
    dbDisconnect(con)
  })
  
  # Handle mentor submission
  observeEvent(input$submit_mentor, {
    req(input$mentor_name, input$mentor_email, input$mentor_title)
    
    con <- dbConnect(RSQLite::SQLite(), DB_NAME)
    
    # Combine expertise and willing to help with NULL safety
    expertise_items <- c(input$mentor_expertise, input$mentor_willing)
    expertise_text <- if(length(expertise_items) == 0) "General mentoring" else paste(expertise_items, collapse = ", ")
    
    # Insert into existing mentor_profiles table
    dbExecute(con, 
              "INSERT INTO mentor_profiles (name, email, title, expertise, bio, industry, 
                                   experience_years, profile_image, active, created_at) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, datetime('now'))",
              params = list(
                input$mentor_name,
                input$mentor_email,
                if(is.null(input$mentor_title)) "Mentor" else input$mentor_title,
                expertise_text,
                if(is.null(input$mentor_bio)) "No bio provided" else input$mentor_bio,
                if(is.null(input$mentor_industry)) "Not specified" else input$mentor_industry,
                if(is.null(input$mentor_experience)) "Not specified" else input$mentor_experience,
                "https://via.placeholder.com/100x100?text=M"
              ))
    
    dbDisconnect(con)
    removeModal()
    
    showNotification("Thank you for registering as a mentor!", type = "message", duration = 5)
  })
  
  # Function to show mentor matches in modal
  show_mentor_matches_modal <- function() {
    req(matches())
    
    showModal(modalDialog(
      title = "Your Mentor Matches",
      size = "xl",
      easyClose = TRUE,
      
      # Display mentor cards in a grid (same as original results_section)
      div(
        style = "padding: 20px;",
        h3("Your Mentor Matches", style = "text-align: center; margin-bottom: 30px;"),
        
        # Display mentor cards in a grid
        div(
          style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px;",
          lapply(matches(), function(mentor) {
            # Ensure all mentor fields are safe
            safe_mentor <- list(
              id = if(is.null(mentor$id)) 1 else mentor$id,
              name = if(is.null(mentor$name)) "Unknown Mentor" else mentor$name,
              title = if(is.null(mentor$title)) "Not specified" else mentor$title,
              industry = if(is.null(mentor$industry)) "Not specified" else mentor$industry,
              experience_years = if(is.null(mentor$experience_years)) "Not specified" else mentor$experience_years,
              expertise = if(is.null(mentor$expertise)) "Not specified" else mentor$expertise,
              score = if(is.null(mentor$score)) 0.75 else mentor$score
            )
            
            div(
              class = "card",
              style = "cursor: pointer; transition: transform 0.3s; height: 420px; position: relative; overflow: hidden;",
              onclick = paste0("Shiny.setInputValue('selected_mentor_id', ", safe_mentor$id, ")"),
              
              div(
                class = "card-body",
                style = "text-align: center; padding: 20px; height: 100%; display: flex; flex-direction: column;",
                
                # Profile Image with Score Badge
                div(
                  style = "position: relative; margin-bottom: 15px;",
                  img(src = "https://via.placeholder.com/120x120?text=M", 
                      style = "width: 120px; height: 120px; border-radius: 50%; border: 3px solid #4f8bb8; object-fit: cover;"),
                  
                  # Compatibility Score Badge
                  div(
                    style = "position: absolute; top: -5px; right: 20px; z-index: 10;",
                    span(
                      paste0("🎯 ", round(safe_mentor$score * 100), "%"),
                      style = "background: linear-gradient(135deg, #28a745 0%, #20c997 100%); 
                               color: white; padding: 6px 12px; border-radius: 20px; 
                               font-weight: 600; font-size: 0.9rem; box-shadow: 0 2px 8px rgba(40,167,69,0.3);"
                    )
                  )
                ),
                
                # Mentor Details
                div(
                  style = "flex-grow: 1;",
                  h5(safe_mentor$name, 
                     style = "color: #2c3e50; margin-bottom: 5px; font-weight: 600;"),
                  h6(safe_mentor$title, 
                     style = "color: #6c757d; margin-bottom: 15px;"),
                  
                  # Industry and Experience
                  p(class = "card-text", 
                    strong("Industry: "), safe_mentor$industry, br(),
                    strong("Experience: "), safe_mentor$experience_years
                  ),
                  
                  # Expertise Preview
                  p(class = "card-text", 
                    strong("Expertise: "), 
                    {
                      expertise <- safe_mentor$expertise
                      if(!is.null(expertise) && !is.na(expertise) && nchar(expertise) > 100) {
                        paste0(substr(expertise, 1, 100), "...")
                      } else {
                        expertise
                      }
                    }
                  )
                ),
                
                # Click to Connect CTA
                div(
                  style = "margin-top: auto;",
                  div(
                    style = "border: 2px dashed #4f8bb8; border-radius: 10px; 
                             padding: 10px; background: rgba(79, 139, 184, 0.05);",
                    p("👆 Click to view full profile and connect!", 
                      style = "font-size: 0.9rem; color: #4f8bb8; margin: 0; font-weight: 600;")
                  )
                )
              )
            )
          })
        )
      ),
      
      footer = div(
        class = "text-center",
        actionButton("back_to_search", "← Search Again", class = "btn-outline-primary")
      )
    ))
  }
  
  # Handle back to search
  observeEvent(input$back_to_search, {
    removeModal()
    matches(NULL)
  })
  
  # Display results (now just a placeholder)
  output$results_section <- renderUI({
    # This section is now handled by the modal
    NULL
  })
  
  # Handle mentor selection
  observeEvent(input$selected_mentor_id, {
    mentor_id <- input$selected_mentor_id
    
    # Find the selected mentor
    mentor <- NULL
    for (m in matches()) {
      if (m$id == mentor_id) {
        mentor <- m
        break
      }
    }
    
    if (!is.null(mentor)) {
      selected_mentor(mentor)
      
      showModal(modalDialog(
        title = paste("Connect with", mentor$name),
        size = "m",
        
        h5("About", mentor$name),
        p(strong("Position: "), if(is.null(mentor$title)) "Not specified" else mentor$title),
        p(strong("Company: "), if(is.null(mentor$company)) "Not specified" else mentor$company),
        p(strong("Industry: "), if(is.null(mentor$industry)) "Not specified" else mentor$industry),
        p(strong("Experience: "), if(is.null(mentor$experience_years)) "Not specified" else mentor$experience_years),
        p(strong("Expertise: "), if(is.null(mentor$expertise)) "Not specified" else mentor$expertise),
        
        hr(),
        
        h5("Professional Bio:"),
        p(if(is.null(mentor$bio)) "No bio available" else mentor$bio),
        
        hr(),
        
        h5("Ready to Connect?"),
        p("Send a personalized introduction message to start your mentoring journey!"),
        
        textAreaInput("intro_message", "Your Message:",
                      height = "150px",
                      placeholder = paste0("Hi ", mentor$name, ", I found your profile on MentorMatch and I'm really interested in connecting because...")),
        
        footer = tagList(
          modalButton("Cancel"),
          actionButton("send_intro", "Send Introduction", class = "btn-primary")
        )
      ))
    }
  })
  
  # Handle sending introduction
  observeEvent(input$send_intro, {
    req(selected_mentor(), student_data$name)
    
    # Get message text with NULL safety
    message_text <- if (!is.null(input$intro_message) && nchar(trimws(input$intro_message)) > 0) {
      input$intro_message
    } else {
      paste0("Hello ", selected_mentor()$name, "! I found your profile through MentorMatch AI and I'm interested in connecting. ",
             "I'm studying ", student_data$major, " and interested in ", student_data$career_interest, ". ",
             "My biggest challenge right now is: ", student_data$challenge)
    }
    
    # Update database with match
    con <- dbConnect(RSQLite::SQLite(), DB_NAME)
    dbExecute(con, "UPDATE students_enhanced SET matched_mentor_id = ? WHERE id = ?",
              params = list(selected_mentor()$id, student_data$id))
    dbDisconnect(con)
    
    # Source email utils and send emails
    source("email_utils.R")
    
    # Send to mentor (using dummy email for testing)
    mentor_email_address <- if(!is.null(selected_mentor()$email) && nchar(selected_mentor()$email) > 0) {
      selected_mentor()$email
    } else {
      "battleshock4@gmail.com"  # Dummy email for testing
    }
    
    send_email_to_mentor(
      student_name = student_data$name,
      student_email = if(!is.null(student_data$email) && nchar(student_data$email) > 0) student_data$email else "battleshock4@gmail.com",
      mentor_email = mentor_email_address,
      mentor_name = selected_mentor()$name,
      mentor_message = message_text
    )
    
    # Send confirmation to student (using dummy email for testing)
    send_confirmation_to_student(
      student_name = student_data$name,
      student_email = if(!is.null(student_data$email) && nchar(student_data$email) > 0) student_data$email else "battleshock4@gmail.com",
      mentor_name = selected_mentor()$name,
      timestamp = Sys.time()
    )
    
    removeModal()
    
    showModal(modalDialog(
      title = "Message Sent!",
      div(
        class = "text-center",
        icon("check-circle", style = "color: green; font-size: 48px;"),
        h4("Success!", style = "margin-top: 20px;"),
        p("Your introduction has been sent to ", strong(selected_mentor()$name), "."),
        p("Check your console for the email messages (in a real app, these would be sent via email)."),
        p("Most mentors respond within 24-48 hours. Good luck!")
      ),
      footer = modalButton("Close"),
      easyClose = TRUE
    ))
  })
}

# Run the app
shinyApp(ui, server)







#' library(shiny)
#' library(bslib)
#' library(DBI)
#' library(RSQLite)
#' library(text2vec)
#' library(Matrix)
#' library(proxy)
#' library(stopwords)
#' library(DT)
#' library(plotly)
#' library(shinyWidgets)
#' library(shinydashboard)
#' library(shinyalert)
#' library(digest)  # For password hashing
#' 
#' # Try to load mailR, fallback if not available
#' tryCatch({
#'   library(mailR)
#' }, error = function(e) {
#'   cat("⚠️ mailR package not available. Email functionality will be limited.\n")
#' })
#' 
#' # Load R6 for OOP and string manipulation
#' library(R6)
#' library(stringr)
#' 
#' # Source utility functions
#' source("mentor_recommender.R")
#' source("email_utils.R")
#' 
#' # Define the %||% operator
#' `%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (is.character(x) && nchar(x) == 0)) y else x
#' 
#' # SMTP Configuration (Production Ready)
#' SMTP_CONFIG <- list(
#'   host = "smtp.gmail.com",  # Change to your SMTP server
#'   port = 587,
#'   username = "your-email@gmail.com",  # Change to your email
#'   password = "your-app-password",     # Change to your app password
#'   tls = TRUE
#' )
#' 
#' # Admin credentials (hashed for security)
#' ADMIN_CREDENTIALS <- list(
#'   admin = digest("mentormatch2024", algo = "sha256"),
#'   superadmin = digest("admin123", algo = "sha256")
#' )
#' 
#' # Enhanced database schema
#' initialize_enhanced_database <- function() {
#'   con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'   
#'   # Users table for authentication
#'   dbExecute(con, "CREATE TABLE IF NOT EXISTS users (
#'     id INTEGER PRIMARY KEY AUTOINCREMENT,
#'     username TEXT UNIQUE NOT NULL,
#'     email TEXT UNIQUE NOT NULL,
#'     password_hash TEXT NOT NULL,
#'     role TEXT DEFAULT 'user',
#'     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     last_login DATETIME,
#'     active BOOLEAN DEFAULT 1
#'   )")
#'   
#'   # Enhanced students table
#'   dbExecute(con, "CREATE TABLE IF NOT EXISTS students_enhanced (
#'     id INTEGER PRIMARY KEY AUTOINCREMENT,
#'     user_id INTEGER,
#'     name TEXT NOT NULL,
#'     email TEXT NOT NULL,
#'     phone TEXT,
#'     profile_image TEXT,
#'     age_range TEXT,
#'     gender TEXT,
#'     ethnicity TEXT,
#'     location TEXT,
#'     education_level TEXT,
#'     field_of_study TEXT,
#'     career_interest TEXT,
#'     experience_level TEXT,
#'     mentorship_goals TEXT,
#'     communication_style TEXT,
#'     availability TEXT,
#'     challenges TEXT,
#'     skills TEXT,
#'     interests TEXT,
#'     linkedin_url TEXT,
#'     github_url TEXT,
#'     portfolio_url TEXT,
#'     matched_mentor_id INTEGER,
#'     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     FOREIGN KEY (user_id) REFERENCES users(id),
#'     FOREIGN KEY (matched_mentor_id) REFERENCES mentor_profiles(id)
#'   )")
#'   
#'   # Enhanced mentors table
#'   dbExecute(con, "CREATE TABLE IF NOT EXISTS mentor_profiles (
#'     id INTEGER PRIMARY KEY AUTOINCREMENT,
#'     user_id INTEGER,
#'     name TEXT NOT NULL,
#'     email TEXT NOT NULL,
#'     phone TEXT,
#'     title TEXT,
#'     company TEXT,
#'     profile_image TEXT,
#'     expertise TEXT,
#'     bio TEXT,
#'     industry TEXT,
#'     experience_years TEXT,
#'     location TEXT,
#'     education TEXT,
#'     skills TEXT,
#'     specializations TEXT,
#'     languages TEXT,
#'     linkedin_url TEXT,
#'     website_url TEXT,
#'     hourly_rate REAL,
#'     availability_hours TEXT,
#'     preferred_mentee_level TEXT,
#'     mentoring_capacity INTEGER DEFAULT 5,
#'     current_mentees INTEGER DEFAULT 0,
#'     rating REAL DEFAULT 0.0,
#'     total_reviews INTEGER DEFAULT 0,
#'     verified BOOLEAN DEFAULT 0,
#'     active BOOLEAN DEFAULT 1,
#'     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     FOREIGN KEY (user_id) REFERENCES users(id)
#'   )")
#'   
#'   # Matches table for tracking relationships
#'   dbExecute(con, "CREATE TABLE IF NOT EXISTS mentor_matches (
#'     id INTEGER PRIMARY KEY AUTOINCREMENT,
#'     student_id INTEGER,
#'     mentor_id INTEGER,
#'     status TEXT DEFAULT 'pending',
#'     compatibility_score REAL,
#'     message TEXT,
#'     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     FOREIGN KEY (student_id) REFERENCES students_enhanced(id),
#'     FOREIGN KEY (mentor_id) REFERENCES mentor_profiles(id)
#'   )")
#'   
#'   # Notifications table
#'   dbExecute(con, "CREATE TABLE IF NOT EXISTS notifications (
#'     id INTEGER PRIMARY KEY AUTOINCREMENT,
#'     user_id INTEGER,
#'     type TEXT,
#'     title TEXT,
#'     message TEXT,
#'     read_status BOOLEAN DEFAULT 0,
#'     action_url TEXT,
#'     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     FOREIGN KEY (user_id) REFERENCES users(id)
#'   )")
#'   
#'   # Reviews table
#'   dbExecute(con, "CREATE TABLE IF NOT EXISTS reviews (
#'     id INTEGER PRIMARY KEY AUTOINCREMENT,
#'     mentor_id INTEGER,
#'     student_id INTEGER,
#'     rating INTEGER,
#'     review_text TEXT,
#'     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
#'     FOREIGN KEY (mentor_id) REFERENCES mentor_profiles(id),
#'     FOREIGN KEY (student_id) REFERENCES students_enhanced(id)
#'   )")
#'   
#'   # Analytics table
#'   dbExecute(con, "CREATE TABLE IF NOT EXISTS analytics (
#'     id INTEGER PRIMARY KEY AUTOINCREMENT,
#'     event_type TEXT,
#'     user_id INTEGER,
#'     metadata TEXT,
#'     created_at DATETIME DEFAULT CURRENT_TIMESTAMP
#'   )")
#'   
#'   dbDisconnect(con)
#' }
#' 
#' # Enhanced authentication functions
#' hash_password <- function(password) {
#'   digest(password, algo = "sha256")
#' }
#' 
#' verify_password <- function(password, hash) {
#'   digest(password, algo = "sha256") == hash
#' }
#' 
#' create_user <- function(username, email, password, role = "user") {
#'   con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'   
#'   # Check if user exists
#'   existing <- dbGetQuery(con, "SELECT id FROM users WHERE username = ? OR email = ?", 
#'                         params = list(username, email))
#'   
#'   if (nrow(existing) > 0) {
#'     dbDisconnect(con)
#'     return(list(success = FALSE, message = "User already exists"))
#'   }
#'   
#'   # Create user
#'   password_hash <- hash_password(password)
#'   result <- dbExecute(con, "INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)",
#'                      params = list(username, email, password_hash, role))
#'   
#'   user_id <- dbGetQuery(con, "SELECT last_insert_rowid() as id")$id
#'   dbDisconnect(con)
#'   
#'   return(list(success = TRUE, user_id = user_id))
#' }
#' 
#' authenticate_user <- function(username, password) {
#'   con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'   
#'   user <- dbGetQuery(con, "SELECT * FROM users WHERE username = ? AND active = 1", 
#'                     params = list(username))
#'   
#'   if (nrow(user) == 0) {
#'     dbDisconnect(con)
#'     return(list(success = FALSE, message = "User not found"))
#'   }
#'   
#'   if (verify_password(password, user$password_hash)) {
#'     # Update last login
#'     dbExecute(con, "UPDATE users SET last_login = datetime('now') WHERE id = ?", 
#'              params = list(user$id))
#'     dbDisconnect(con)
#'     return(list(success = TRUE, user = user))
#'   } else {
#'     dbDisconnect(con)
#'     return(list(success = FALSE, message = "Invalid password"))
#'   }
#' }
#' 
#' # Enhanced email functions with SMTP
#' send_smtp_email <- function(to, subject, body, from = SMTP_CONFIG$username) {
#'   tryCatch({
#'     if (SMTP_CONFIG$username != "your-email@gmail.com") {  # Only if configured
#'       mailR::send.mail(
#'         from = from,
#'         to = to,
#'         subject = subject,
#'         body = body,
#'         smtp = list(
#'           host.name = SMTP_CONFIG$host,
#'           port = SMTP_CONFIG$port,
#'           user.name = SMTP_CONFIG$username,
#'           passwd = SMTP_CONFIG$password,
#'           ssl = SMTP_CONFIG$tls
#'         ),
#'         authenticate = TRUE,
#'         send = TRUE
#'       )
#'       return(TRUE)
#'     } else {
#'       # Fallback to console mode
#'       cat("📧 EMAIL (SMTP not configured - console mode):\n")
#'       cat("To:", to, "\n")
#'       cat("Subject:", subject, "\n")
#'       cat("Body:", body, "\n")
#'       cat("----------------------------------------\n")
#'       return(FALSE)
#'     }
#'   }, error = function(e) {
#'     cat("Email sending failed:", e$message, "\n")
#'     # Fallback to console
#'     cat("📧 EMAIL (SMTP failed - console mode):\n")
#'     cat("To:", to, "\n")
#'     cat("Subject:", subject, "\n")
#'     cat("Body:", body, "\n")
#'     cat("----------------------------------------\n")
#'     return(FALSE)
#'   })
#' }
#' 
#' # Enhanced notification system
#' create_notification <- function(user_id, type, title, message, action_url = NULL) {
#'   con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'   
#'   dbExecute(con, "INSERT INTO notifications (user_id, type, title, message, action_url) VALUES (?, ?, ?, ?, ?)",
#'            params = list(user_id, type, title, message, action_url))
#'   
#'   dbDisconnect(con)
#' }
#' 
#' get_user_notifications <- function(user_id, unread_only = FALSE) {
#'   con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'   
#'   query <- "SELECT * FROM notifications WHERE user_id = ?"
#'   if (unread_only) {
#'     query <- paste(query, "AND read_status = 0")
#'   }
#'   query <- paste(query, "ORDER BY created_at DESC LIMIT 50")
#'   
#'   notifications <- dbGetQuery(con, query, params = list(user_id))
#'   dbDisconnect(con)
#'   
#'   return(notifications)
#' }
#' 
#' # Enhanced matching algorithm with advanced filtering
#' advanced_mentor_search <- function(filters = list()) {
#'   con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'   
#'   query <- "SELECT * FROM mentor_profiles WHERE active = 1"
#'   params <- list()
#'   
#'   if (!is.null(filters$industry) && filters$industry != "") {
#'     query <- paste(query, "AND industry = ?")
#'     params <- append(params, filters$industry)
#'   }
#'   
#'   if (!is.null(filters$experience_min)) {
#'     query <- paste(query, "AND CAST(SUBSTR(experience_years, 1, 2) AS INTEGER) >= ?")
#'     params <- append(params, filters$experience_min)
#'   }
#'   
#'   if (!is.null(filters$location) && filters$location != "") {
#'     query <- paste(query, "AND location LIKE ?")
#'     params <- append(params, paste0("%", filters$location, "%"))
#'   }
#'   
#'   if (!is.null(filters$rating_min)) {
#'     query <- paste(query, "AND rating >= ?")
#'     params <- append(params, filters$rating_min)
#'   }
#'   
#'   if (!is.null(filters$availability) && filters$availability == TRUE) {
#'     query <- paste(query, "AND current_mentees < mentoring_capacity")
#'   }
#'   
#'   query <- paste(query, "ORDER BY rating DESC, total_reviews DESC")
#'   
#'   mentors <- dbGetQuery(con, query, params = params)
#'   dbDisconnect(con)
#'   
#'   return(mentors)
#' }
#' 
#' # Modern theme with PWA support
#' app_theme <- bs_theme(
#'   version = 5,
#'   preset = "bootstrap",
#'   primary = "#4f8bb8",
#'   secondary = "#69b7d1", 
#'   success = "#52c3a4",
#'   bg = "#ffffff",
#'   fg = "#2c3e50",
#'   base_font = font_google("Inter"),
#'   heading_font = font_google("Poppins", wght = c(400, 600, 700))
#' )
#' 
#' # Initialize database on app start
#' initialize_enhanced_database()
#' 
#' ui <- page_navbar(
#'   title = "🎯 MentorMatch AI Enhanced",
#'   theme = app_theme,
#'   bg = "primary",
#'   inverse = TRUE,
#'   
#'   # PWA and Mobile Optimization
#'   tags$head(
#'     tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
#'     tags$meta(name = "theme-color", content = "#4f8bb8"),
#'     tags$link(rel = "manifest", href = "manifest.json"),
#'     tags$link(rel = "icon", href = "favicon.ico"),
#'     
#'     # Enhanced CSS with mobile responsiveness
#'     tags$style(HTML("
#'       :root {
#'         --primary-gradient: linear-gradient(135deg, #4f8bb8 0%, #69b7d1 100%);
#'         --success-gradient: linear-gradient(135deg, #52c3a4 0%, #20c997 100%);
#'         --admin-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
#'       }
#'       
#'       .admin-fab {
#'         position: fixed !important;
#'         bottom: 25px !important;
#'         right: 25px !important;
#'         z-index: 99999 !important;
#'         width: 70px !important;
#'         height: 70px !important;
#'         border-radius: 50% !important;
#'         background: var(--admin-gradient) !important;
#'         border: 4px solid white !important;
#'         color: white !important;
#'         font-size: 30px !important;
#'         box-shadow: 0 8px 25px rgba(102, 126, 234, 0.5) !important;
#'         transition: all 0.3s ease !important;
#'         animation: pulse 2s infinite !important;
#'       }
#'       
#'       .profile-upload {
#'         border: 2px dashed #ddd;
#'         border-radius: 10px;
#'         padding: 20px;
#'         text-align: center;
#'         cursor: pointer;
#'         transition: all 0.3s ease;
#'       }
#'       
#'       .profile-upload:hover {
#'         border-color: var(--bs-primary);
#'         background-color: rgba(79, 139, 184, 0.05);
#'       }
#'       
#'       .notification-badge {
#'         position: absolute;
#'         top: -5px;
#'         right: -5px;
#'         background: #dc3545;
#'         color: white;
#'         border-radius: 50%;
#'         width: 20px;
#'         height: 20px;
#'         font-size: 12px;
#'         display: flex;
#'         align-items: center;
#'         justify-content: center;
#'       }
#'       
#'       .mentor-card {
#'         transition: all 0.3s ease;
#'         border: none;
#'         box-shadow: 0 4px 15px rgba(0,0,0,0.1);
#'         border-radius: 15px;
#'         overflow: hidden;
#'       }
#'       
#'       .mentor-card:hover {
#'         transform: translateY(-5px);
#'         box-shadow: 0 8px 25px rgba(0,0,0,0.15);
#'       }
#'       
#'       .rating-stars {
#'         color: #ffc107;
#'         font-size: 1.2rem;
#'       }
#'       
#'       .search-filters {
#'         background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
#'         border-radius: 15px;
#'         padding: 20px;
#'         margin: 20px 0;
#'       }
#'       
#'       @media (max-width: 768px) {
#'         .admin-fab {
#'           width: 60px !important;
#'           height: 60px !important;
#'           font-size: 24px !important;
#'         }
#'         
#'         .hero-section {
#'           padding: 40px 15px !important;
#'         }
#'         
#'         .hero-section h1 {
#'           font-size: 2.5rem !important;
#'         }
#'       }
#'       
#'       /* PWA Install Button */
#'       .pwa-install {
#'         background: var(--success-gradient);
#'         border: none;
#'         color: white;
#'         padding: 10px 20px;
#'         border-radius: 25px;
#'         font-weight: 600;
#'         position: fixed;
#'         top: 20px;
#'         right: 20px;
#'         z-index: 1000;
#'         display: none;
#'       }
#'       
#'       @keyframes pulse {
#'         0% { box-shadow: 0 8px 25px rgba(102, 126, 234, 0.5); }
#'         50% { box-shadow: 0 8px 25px rgba(102, 126, 234, 0.8), 0 0 0 10px rgba(102, 126, 234, 0.2); }
#'         100% { box-shadow: 0 8px 25px rgba(102, 126, 234, 0.5); }
#'       }
#'       
#'       /* Enhanced mentor match cards */
#'       .mentor-match-card {
#'         transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
#'         border: 1px solid rgba(var(--bs-primary-rgb), 0.15);
#'         background: linear-gradient(145deg, #ffffff 0%, #f8f9fa 100%);
#'       }
#'       
#'       .mentor-match-card:hover {
#'         border: 1px solid var(--bs-primary);
#'         transform: translateY(-10px) scale(1.02);
#'         box-shadow: 0 20px 40px rgba(var(--bs-primary-rgb), 0.25);
#'         background: linear-gradient(145deg, #ffffff 0%, #f0f7ff 100%);
#'       }
#'       
#'       .mentor-profile-img {
#'         transition: all 0.4s ease;
#'         filter: brightness(1) saturate(1);
#'       }
#'       
#'       .mentor-match-card:hover .mentor-profile-img {
#'         transform: scale(1.08);
#'         box-shadow: 0 12px 25px rgba(var(--bs-primary-rgb), 0.3);
#'         filter: brightness(1.1) saturate(1.2);
#'       }
#'       
#'       .mentor-score-badge {
#'         transition: all 0.4s ease;
#'         position: relative;
#'         overflow: hidden;
#'       }
#'       
#'       .mentor-match-card:hover .mentor-score-badge {
#'         transform: scale(1.15);
#'         box-shadow: 0 8px 20px rgba(var(--bs-primary-rgb), 0.5);
#'       }
#'       
#'       .mentor-score-badge::before {
#'         content: '';
#'         position: absolute;
#'         top: -50%;
#'         left: -50%;
#'         width: 200%;
#'         height: 200%;
#'         background: linear-gradient(45deg, transparent, rgba(255,255,255,0.3), transparent);
#'         transform: rotate(45deg);
#'         transition: all 0.6s ease;
#'         opacity: 0;
#'       }
#'       
#'       .mentor-match-card:hover .mentor-score-badge::before {
#'         animation: shine 0.8s ease-in-out;
#'         opacity: 1;
#'       }
#'       
#'       @keyframes shine {
#'         0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
#'         100% { transform: translateX(100%) translateY(100%) rotate(45deg); }
#'       }
#'       
#'       .mentor-connect-prompt {
#'         transition: all 0.3s ease;
#'         opacity: 0.8;
#'       }
#'       
#'       .mentor-match-card:hover .mentor-connect-prompt {
#'         opacity: 1;
#'         transform: scale(1.05);
#'         background: rgba(var(--bs-primary-rgb), 0.15) !important;
#'         border-color: var(--bs-primary) !important;
#'       }
#'     "))
#'   ),
#'   
#'   # Home Panel - No authentication required
#'   nav_panel(
#'     title = "Home",
#'     layout_columns(
#'       col_widths = 12,
#'       
#'       # Hero Section
#'       div(
#'         class = "hero-section",
#'         style = "background: var(--primary-gradient); color: white; padding: 80px 20px; text-align: center; margin: -20px -15px 40px -15px; border-radius: 0 0 20px 20px;",
#'         h1("🎯 MentorMatch AI Enhanced", 
#'            style = "font-size: 3.5rem; font-weight: 700; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
#'         p("Connect with the perfect mentor using AI-powered semantic matching", 
#'           style = "font-size: 1.3rem; margin-bottom: 40px; opacity: 0.95;"),
#'         
#'         div(
#'           style = "display: flex; justify-content: center; gap: 20px; flex-wrap: wrap;",
#'           actionButton("show_student_modal", 
#'                       "🎓 I'm a Student", 
#'                       class = "btn-light btn-lg",
#'                       style = "padding: 15px 30px; font-size: 1.1rem; font-weight: 600; border-radius: 50px; min-width: 200px; box-shadow: 0 4px 15px rgba(0,0,0,0.2);"),
#'           actionButton("show_mentor_modal", 
#'                       "👨‍🏫 I'm a Mentor", 
#'                       class = "btn-outline-light btn-lg",
#'                       style = "padding: 15px 30px; font-size: 1.1rem; font-weight: 600; border-radius: 50px; min-width: 200px; box-shadow: 0 4px 15px rgba(0,0,0,0.2);")
#'         )
#'       ),
#'       
#'       # Features Section  
#'       layout_columns(
#'         col_widths = c(4, 4, 4),
#'         
#'         card(
#'           card_header("🧠 AI-Powered Matching"),
#'           card_body(
#'             p("Our advanced semantic analysis finds mentors that truly align with your goals, interests, and learning style."),
#'             p(strong("✓ Compatibility Scoring"), br(),
#'               "✓ Personalized Recommendations", br(),
#'               "✓ Smart Question Analysis")
#'           )
#'         ),
#'         
#'         card(
#'           card_header("🎯 Perfect Connections"),
#'           card_body(
#'             p("Connect with mentors who have the exact expertise and experience you're looking for in your field."),
#'             p(strong("✓ Industry Experts"), br(),
#'               "✓ Enhanced Profiles", br(),
#'               "✓ Diverse Backgrounds")
#'           )
#'         ),
#'         
#'         card(
#'           card_header("📧 Professional Communication"),
#'           card_body(
#'             p("Send personalized introduction messages and get connected with your ideal mentor instantly."),
#'             p(strong("✓ SMTP Email Integration"), br(),
#'               "✓ Custom Messages", br(),
#'               "✓ Quick Responses")
#'           )
#'         )
#'       ),
#'       
#'       # Results section (hidden initially)
#'       uiOutput("results_section")
#'     )
#'   ),
#'   
#'   # Enhanced About Panel
#'   nav_panel("About", 
#'     layout_columns(
#'       col_widths = 12,
#'       card(
#'         card_header("About MentorMatch AI Enhanced"),
#'         card_body(
#'           h4("🚀 Next-Generation Mentorship Platform"),
#'           p("MentorMatch AI Enhanced combines advanced AI technology with comprehensive user management, notifications, and professional features."),
#'           
#'           h5("✨ New Features:"),
#'           tags$ul(
#'             tags$li("🔐 Secure user authentication and profiles"),
#'             tags$li("📧 SMTP email integration for production"),
#'             tags$li("📱 Mobile-responsive design with PWA support"),
#'             tags$li("🔍 Advanced search and filtering"),
#'             tags$li("🔔 Real-time notification system"),
#'             tags$li("⭐ Rating and review system"),
#'             tags$li("📊 Enhanced analytics dashboard"),
#'             tags$li("📸 Profile image upload functionality")
#'           ),
#'           
#'           h5("🛠 Technology Stack:"),
#'           p("Built with R Shiny, bslib, SQLite, text2vec, plotly, and enhanced with shinyWidgets, mailR, and digest for advanced functionality.")
#'         )
#'       )
#'     )
#'   ),
#'   
#'   # Floating Admin Button (Enhanced)
#'   tags$div(
#'     class = "admin-fab-container",
#'     style = "position: fixed; bottom: 20px; right: 20px; z-index: 100000;",
#'     actionButton("show_admin", HTML("⚙️"), 
#'                 class = "admin-fab",
#'                 title = "Admin Dashboard")
#'   )
#' )
#' 
#' server <- function(input, output, session) {
#'   # Reactive values
#'   student_data <- reactiveValues()
#'   mentor_data <- reactiveValues()
#'   matches <- reactiveVal(NULL)
#'   selected_mentor <- reactiveVal(NULL)
#'   embedding_system <- reactiveVal(NULL)
#'   admin_logged_in <- reactiveVal(FALSE)
#'   
#'   # Initialize database and embedding system
#'   observe({
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     
#'     # Ensure basic tables exist
#'     dbExecute(con, "CREATE TABLE IF NOT EXISTS mentors (id INTEGER PRIMARY KEY, name TEXT, email TEXT, majors TEXT, industries TEXT, offers TEXT, comm TEXT, aspects TEXT, bio TEXT)")
#'     dbExecute(con, "CREATE TABLE IF NOT EXISTS students (id INTEGER PRIMARY KEY, name TEXT, email TEXT, majors TEXT, industries TEXT, looking_for TEXT, comm TEXT, aspects TEXT, challenge TEXT, matched_mentor_id INTEGER)")
#'     
#'     # Check if we have mentors in the enhanced table
#'     mentor_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM mentor_profiles")$n
#'     
#'     # Initialize embedding system if enough mentors
#'     if (mentor_count >= 3) {
#'       tryCatch({
#'         embedding_system(default_embedding_system(con))
#'         message("✓ Semantic recommendation system initialized")
#'       }, error = function(e) {
#'         message("⚠ Could not initialize semantic system: ", e$message)
#'       })
#'     }
#'     
#'     dbDisconnect(con)
#'   })
#'   
#'   # Student Modal
#'   observeEvent(input$show_student_modal, {
#'     showModal(modalDialog(
#'       title = div(
#'         style = "background: var(--primary-gradient); 
#'                  color: white; padding: 20px; margin: -15px -15px 20px -15px; border-radius: 10px;",
#'         h3("🎓 Student Questionnaire", style = "margin: 0; font-weight: 600;"),
#'         p("Help us find your perfect mentor match!", style = "margin: 5px 0 0 0; opacity: 0.9;")
#'       ),
#'       size = "l",
#'       
#'       layout_columns(
#'         col_widths = c(6, 6),
#'         
#'         # Left Column
#'         div(
#'           h5("👤 Personal Information", style = "color: var(--bs-primary); margin-bottom: 15px;"),
#'           textInput("student_name", "Full Name", placeholder = "Alex Johnson"),
#'           textInput("student_email", "Email Address", placeholder = "alex@university.edu"),
#'           
#'           h5("🎯 Academic Focus", style = "color: var(--bs-primary); margin-top: 25px; margin-bottom: 15px;"),
#'           selectInput("student_major", "Primary Academic Interest", 
#'                      choices = list(
#'                        "STEM" = c("Computer Science", "Engineering", "Mathematics", "Physics", "Biology", "Chemistry"),
#'                        "Business & Economics" = c("Business Administration", "Economics", "Finance", "Marketing", "Entrepreneurship"),
#'                        "Social Sciences" = c("Psychology", "Sociology", "Political Science", "International Relations"),
#'                        "Humanities" = c("English Literature", "History", "Philosophy", "Languages", "Art"),
#'                        "Health & Medicine" = c("Pre-Med", "Nursing", "Public Health", "Biomedical Sciences"),
#'                        "Other" = c("Law", "Education", "Communications", "Environmental Studies", "Other")
#'                      ),
#'                      selected = NULL),
#'           
#'           selectInput("student_level", "Academic Level", 
#'                      choices = c("High School Student", "Undergraduate", "Graduate Student", "Recent Graduate", "Career Changer"),
#'                      selected = NULL)
#'         ),
#'         
#'         # Right Column  
#'         div(
#'           h5("💼 Career Goals", style = "color: var(--bs-primary); margin-bottom: 15px;"),
#'           selectInput("career_interest", "Target Industry", 
#'                      choices = c("Technology & Software", "Healthcare & Medicine", "Business & Finance", 
#'                                 "Education & Academia", "Government & Public Policy", "Non-profit & Social Impact",
#'                                 "Creative & Media", "Engineering & Manufacturing", "Research & Development", "Other"),
#'                      selected = NULL),
#'           
#'           selectInput("career_stage", "Career Goal Timeline", 
#'                      choices = c("Exploring different paths", "Preparing for internships", "Job searching", 
#'                                 "Planning graduate school", "Changing career direction", "Starting my own business"),
#'                      selected = NULL),
#'           
#'           h5("🤝 Mentorship Preferences", style = "color: var(--bs-primary); margin-top: 25px; margin-bottom: 15px;"),
#'           checkboxGroupInput("mentorship_type", "What kind of guidance do you need?",
#'                            choices = c("Career planning & strategy" = "career_planning",
#'                                      "Industry insights & networking" = "networking", 
#'                                      "Skill development & learning" = "skills",
#'                                      "Job search & interview prep" = "job_prep",
#'                                      "Graduate school guidance" = "grad_school",
#'                                      "Personal development & confidence" = "personal_dev"),
#'                            selected = NULL),
#'           
#'           textAreaInput("biggest_challenge", "What's your biggest current challenge or goal?", 
#'                        height = "80px",
#'                        placeholder = "e.g., 'I'm struggling to choose between different career paths in tech...'")
#'         )
#'       ),
#'       
#'       footer = tagList(
#'         modalButton("Cancel"),
#'         actionButton("submit_student", "🔍 Find My Mentor!", class = "btn-primary btn-lg")
#'       ),
#'       
#'       easyClose = FALSE
#'     ))
#'   })
#'   
#'   # Mentor Modal
#'   observeEvent(input$show_mentor_modal, {
#'     showModal(modalDialog(
#'       title = div(
#'         style = "background: var(--success-gradient); 
#'                  color: white; padding: 20px; margin: -15px -15px 20px -15px; border-radius: 10px;",
#'         h3("👨‍🏫 Mentor Registration", style = "margin: 0; font-weight: 600;"),
#'         p("Share your expertise and help the next generation!", style = "margin: 5px 0 0 0; opacity: 0.9;")
#'       ),
#'       size = "l",
#'       
#'       layout_columns(
#'         col_widths = c(6, 6),
#'         
#'         # Left Column
#'         div(
#'           h5("👤 Professional Information", style = "color: var(--bs-success); margin-bottom: 15px;"),
#'           textInput("mentor_name", "Full Name", placeholder = "Dr. Jane Smith"),
#'           textInput("mentor_email", "Email Address", placeholder = "jane@company.com"),
#'           textInput("mentor_title", "Current Position", placeholder = "Senior Data Scientist at TechCorp"),
#'           
#'           selectInput("mentor_industry", "Primary Industry", 
#'                      choices = c("Technology & Software", "Healthcare & Medicine", "Business & Finance", 
#'                                 "Education & Academia", "Government & Public Policy", "Non-profit & Social Impact",
#'                                 "Creative & Media", "Engineering & Manufacturing", "Research & Development", "Other"),
#'                      selected = NULL),
#'           
#'           selectInput("mentor_experience", "Years of Experience", 
#'                      choices = c("3-5 years", "5-10 years", "10-15 years", "15+ years"),
#'                      selected = NULL)
#'         ),
#'         
#'         # Right Column
#'         div(
#'           h5("🎯 Expertise & Mentoring", style = "color: var(--bs-success); margin-bottom: 15px;"),
#'           checkboxGroupInput("mentor_expertise", "Areas of Expertise",
#'                            choices = c("Technical skills & programming" = "technical",
#'                                      "Career strategy & planning" = "career_strategy", 
#'                                      "Leadership & management" = "leadership",
#'                                      "Entrepreneurship & startups" = "entrepreneurship",
#'                                      "Research & academia" = "research",
#'                                      "Industry networking" = "networking",
#'                                      "Graduate school prep" = "grad_prep",
#'                                      "Interview & job search" = "interview_prep"),
#'                            selected = NULL),
#'           
#'           checkboxGroupInput("mentor_willing", "I'm willing to help with:",
#'                            choices = c("One-on-one mentoring sessions" = "one_on_one",
#'                                      "Resume & portfolio reviews" = "resume_review",
#'                                      "Mock interviews & prep" = "interview_practice", 
#'                                      "Industry introductions" = "introductions",
#'                                      "Career advice & planning" = "career_advice",
#'                                      "Skill development guidance" = "skill_guidance"),
#'                            selected = NULL),
#'           
#'           selectInput("communication_pref", "Preferred Communication", 
#'                      choices = c("Email exchanges", "Video calls (30-60 min)", "Phone calls", "In-person meetings", "Flexible - any method"),
#'                      selected = NULL),
#'           
#'           textAreaInput("mentor_bio", "Professional Bio & Mentoring Philosophy", 
#'                        height = "100px",
#'                        placeholder = "Tell potential mentees about your background and what you can offer...")
#'         )
#'       ),
#'       
#'       footer = tagList(
#'         modalButton("Cancel"),
#'         actionButton("submit_mentor", "🚀 Join as Mentor", class = "btn-success btn-lg")
#'       ),
#'       
#'       easyClose = FALSE
#'     ))
#'   })
#'   
#'   # Handle student submission
#'   observeEvent(input$submit_student, {
#'     req(input$student_name, input$student_email, input$student_major, input$career_interest)
#'     
#'     # Store student data
#'     student_data$name <- input$student_name
#'     student_data$email <- input$student_email
#'     student_data$major <- input$student_major
#'     student_data$career_interest <- input$career_interest
#'     student_data$career_stage <- input$career_stage
#'     student_data$mentorship_type <- paste(input$mentorship_type, collapse = ", ")
#'     student_data$challenge <- input$biggest_challenge
#'     student_data$level <- input$student_level
#'     
#'     # Save to database
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     dbExecute(con, "INSERT INTO students (name, email, majors, industries, looking_for, comm, aspects, challenge) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
#'               params = list(
#'                 student_data$name,
#'                 student_data$email,
#'                 student_data$major,
#'                 student_data$career_interest,
#'                 student_data$mentorship_type,
#'                 input$communication_pref %||% "Email",
#'                 student_data$career_stage,
#'                 student_data$challenge
#'               ))
#'     
#'     student_row <- dbGetQuery(con, "SELECT id FROM students WHERE email = ? ORDER BY id DESC LIMIT 1", 
#'                               params = list(student_data$email))
#'     student_data$id <- student_row$id[1]
#'     
#'     removeModal()
#'     
#'     # Check if enough mentors exist
#'     mentor_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM mentor_profiles")$n
#'     
#'     if (mentor_count >= 3) {
#'       # Use semantic recommendation system
#'       if (!is.null(embedding_system())) {
#'         student_answers <- list(
#'           major = student_data$major,
#'           career = student_data$career_interest,
#'           mentorship = student_data$mentorship_type,
#'           challenge = student_data$challenge,
#'           level = student_data$level,
#'           stage = student_data$career_stage
#'         )
#'         
#'         recommendations <- get_mentor_recommendations(student_answers, embedding_system(), top_k = 3)
#'         matches(recommendations)
#'       } else {
#'         # Fallback to simple matching
#'         mentors <- dbGetQuery(con, "SELECT * FROM mentor_profiles LIMIT 3")
#'         simple_matches <- lapply(seq_len(nrow(mentors)), function(i) {
#'           mentor <- as.list(mentors[i, ])
#'           mentor$score <- 0.75 + runif(1, -0.1, 0.1) # Random score between 0.65-0.85
#'           mentor
#'         })
#'         matches(simple_matches)
#'       }
#'     } else {
#'       showModal(modalDialog(
#'         title = "🔍 Building Our Mentor Network",
#'         div(
#'           class = "text-center",
#'           h4("We're still growing our mentor community!"),
#'           p("We don't have enough mentors yet to provide quality matches for your specific interests."),
#'           br(),
#'           div(
#'             style = "background: var(--primary-gradient); 
#'                      color: white; padding: 20px; border-radius: 10px;",
#'             h5("📧 We'll notify you when we find perfect matches!"),
#'             p("Based on your interests in ", strong(student_data$major), " and ", strong(student_data$career_interest), 
#'               ", we'll prioritize finding mentors in these areas.")
#'           )
#'         ),
#'         easyClose = TRUE,
#'         footer = actionButton("student_insufficient_ok", "📧 Notify Me When Ready", class = "btn-primary")
#'       ))
#'     }
#'     dbDisconnect(con)
#'   })
#'   
#'   # Handle mentor submission
#'   observeEvent(input$submit_mentor, {
#'     req(input$mentor_name, input$mentor_email, input$mentor_title)
#'     
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     
#'     # Store mentor data
#'     expertise_text <- paste(c(input$mentor_expertise, input$mentor_willing), collapse = ", ")
#'     
#'     # Insert into simple mentors table
#'     dbExecute(con, "INSERT INTO mentors (name, email, majors, industries, offers, comm, aspects, bio) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
#'               params = list(
#'                 input$mentor_name,
#'                 input$mentor_email,
#'                 input$mentor_industry,
#'                 input$mentor_industry,
#'                 expertise_text,
#'                 input$communication_pref,
#'                 input$mentor_experience,
#'                 input$mentor_bio
#'               ))
#'     
#'     # Also insert into mentor_profiles for semantic matching
#'     dbExecute(con, "INSERT INTO mentor_profiles (name, title, expertise, bio, email, profile_image) VALUES (?, ?, ?, ?, ?, ?)",
#'               params = list(
#'                 input$mentor_name,
#'                 input$mentor_title,
#'                 expertise_text,
#'                 input$mentor_bio,
#'                 input$mentor_email,
#'                 "https://via.placeholder.com/100x100?text=M" # Default image
#'               ))
#'     
#'     dbDisconnect(con)
#'     removeModal()
#'     
#'     showModal(modalDialog(
#'       title = "🎉 Welcome to MentorMatch!",
#'       div(
#'         class = "text-center",
#'         h4("Thank you for joining our mentor community!"),
#'         p("Your profile has been created successfully."),
#'         div(
#'           style = "background: var(--success-gradient); 
#'                    color: white; padding: 20px; border-radius: 10px; margin: 20px 0;",
#'           h5("🌟 Ready to make a difference!"),
#'           p("You'll receive email notifications when students are interested in connecting with you.")
#'         ),
#'         p("Your expertise in ", strong(input$mentor_industry), " will help shape the next generation of professionals.")
#'       ),
#'       easyClose = TRUE,
#'       footer = actionButton("mentor_ok", "🚀 Start Mentoring", class = "btn-success")
#'     ))
#'   })
#'   
#'   # Handle insufficient mentors OK
#'   observeEvent(input$student_insufficient_ok, {
#'     removeModal()
#'   })
#'   
#'   # Handle mentor OK
#'   observeEvent(input$mentor_ok, {
#'     removeModal()
#'   })
#'   
#'   # Admin panel (existing logic)
#'   observeEvent(input$show_admin, {
#'     showModal(modalDialog(
#'       title = div(
#'         style = "background: var(--admin-gradient); color: white; padding: 20px; margin: -15px -15px 20px -15px; border-radius: 10px;",
#'         h3("🔐 Admin Login", style = "margin: 0; font-weight: 600;")
#'       ),
#'       size = "m",
#'       
#'       textInput("admin_username", "Username", placeholder = "Enter admin username"),
#'       passwordInput("admin_password", "Password", placeholder = "Enter admin password"),
#'       
#'       footer = tagList(
#'         modalButton("Cancel"),
#'         actionButton("admin_login", "🚀 Login", class = "btn-primary btn-lg")
#'       )
#'     ))
#'   })
#'   
#'   # Admin login
#'   observeEvent(input$admin_login, {
#'     username <- input$admin_username
#'     password <- input$admin_password
#'     
#'     if (username %in% names(ADMIN_CREDENTIALS) && 
#'         hash_password(password) == ADMIN_CREDENTIALS[[username]]) {
#'       
#'       admin_logged_in(TRUE)
#'       removeModal()
#'       
#'       # Show enhanced admin dashboard
#'       showModal(modalDialog(
#'         title = div(
#'           style = "background: var(--admin-gradient); color: white; padding: 20px; margin: -15px -15px 20px -15px; border-radius: 10px;",
#'           h3("📊 Enhanced Admin Dashboard", style = "margin: 0; font-weight: 600;"),
#'           div(
#'             style = "position: absolute; top: 15px; right: 15px;",
#'             actionButton("admin_logout", "🚪 Logout", class = "btn-outline-light btn-sm")
#'           )
#'         ),
#'         size = "xl",
#'         
#'         # Enhanced dashboard content with real-time stats
#'         layout_columns(
#'           col_widths = c(3, 3, 3, 3),
#'           
#'           div(
#'             class = "stats-card",
#'             style = "background: var(--success-gradient);",
#'             uiOutput("total_users_stat")
#'           ),
#'           
#'           div(
#'             class = "stats-card",
#'             style = "background: var(--primary-gradient);",
#'             uiOutput("active_mentors_stat")
#'           ),
#'           
#'           div(
#'             class = "stats-card",
#'             style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);",
#'             uiOutput("students_stat")
#'           ),
#'           
#'           div(
#'             class = "stats-card",
#'             style = "background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);",
#'             uiOutput("match_rate_stat")
#'           )
#'         ),
#'         
#'         br(),
#'         
#'         # Enhanced analytics tabs
#'         navset_card_tab(
#'           nav_panel("📈 Analytics", 
#'             layout_columns(
#'               col_widths = c(6, 6),
#'               
#'               # User Growth Chart
#'               card(
#'                 card_header("📈 User Growth Over Time"),
#'                 card_body(
#'                   plotlyOutput("user_growth_chart", height = "300px")
#'                 )
#'               ),
#'               
#'               # Match Success Rate
#'               card(
#'                 card_header("🎯 Matching Success Rate"),
#'                 card_body(
#'                   plotlyOutput("success_rate_chart", height = "300px")
#'                 )
#'               )
#'             ),
#'             
#'             br(),
#'             
#'             layout_columns(
#'               col_widths = c(4, 4, 4),
#'               
#'               # Top Mentors
#'               card(
#'                 card_header("🌟 Top Rated Mentors"),
#'                 card_body(
#'                   DT::dataTableOutput("top_mentors_table")
#'                 )
#'               ),
#'               
#'               # Popular Industries
#'               card(
#'                 card_header("🏢 Popular Industries"),
#'                 card_body(
#'                   plotlyOutput("industry_chart", height = "250px")
#'                 )
#'               ),
#'               
#'               # Recent Activity
#'               card(
#'                 card_header("⚡ Recent Activity"),
#'                 card_body(
#'                   DT::dataTableOutput("recent_activity_table")
#'                 )
#'               )
#'             )
#'           ),
#'           nav_panel("👥 User Management",
#'             layout_columns(
#'               col_widths = 12,
#'               
#'               card(
#'                 card_header("👥 User Administration"),
#'                 card_body(
#'                   h5("All Registered Users"),
#'                   DT::dataTableOutput("all_users_table"),
#'                   
#'                   br(),
#'                   
#'                   div(
#'                     style = "text-align: center;",
#'                     actionButton("export_users", "📊 Export User Data", class = "btn-primary"),
#'                     actionButton("send_bulk_notification", "📧 Send Bulk Notification", class = "btn-warning", style = "margin-left: 10px;")
#'                   )
#'                 )
#'               )
#'             )
#'           ),
#'           nav_panel("🔔 Notifications",
#'             layout_columns(
#'               col_widths = c(6, 6),
#'               
#'               card(
#'                 card_header("📤 Send Notification"),
#'                 card_body(
#'                   selectInput("notification_type", "Notification Type",
#'                             choices = c("System Update", "New Feature", "Maintenance", "Promotion", "General")),
#'                   textInput("notification_title", "Title", placeholder = "Enter notification title"),
#'                   textAreaInput("notification_message", "Message", 
#'                                height = "120px",
#'                                placeholder = "Enter your message here..."),
#'                   selectInput("notification_target", "Send To",
#'                             choices = c("All Users" = "all", "Students Only" = "students", "Mentors Only" = "mentors")),
#'                   actionButton("send_notification", "📤 Send Notification", class = "btn-success btn-lg")
#'                 )
#'               ),
#'               
#'               card(
#'                 card_header("📋 Notification History"),
#'                 card_body(
#'                   DT::dataTableOutput("notification_history_table")
#'                 )
#'               )
#'             )
#'           ),
#'           nav_panel("⚙️ System Settings",
#'             layout_columns(
#'               col_widths = c(6, 6),
#'               
#'               card(
#'                 card_header("📧 Email Configuration"),
#'                 card_body(
#'                   h5("SMTP Settings"),
#'                   textInput("smtp_host", "SMTP Host", value = "smtp.gmail.com"),
#'                   numericInput("smtp_port", "SMTP Port", value = 587, min = 1, max = 65535),
#'                   textInput("smtp_username", "Email Username"),
#'                   passwordInput("smtp_password", "Email Password"),
#'                   checkboxInput("smtp_tls", "Use TLS", value = TRUE),
#'                   actionButton("test_email", "📧 Test Email", class = "btn-info"),
#'                   actionButton("save_smtp", "💾 Save Settings", class = "btn-success")
#'                 )
#'               ),
#'               
#'               card(
#'                 card_header("🔧 System Maintenance"),
#'                 card_body(
#'                   h5("Database Operations"),
#'                   p("Last backup: ", strong("2024-12-31 10:30:00")),
#'                   actionButton("backup_db", "💾 Backup Database", class = "btn-warning"),
#'                   br(), br(),
#'                   actionButton("clear_logs", "🗑️ Clear System Logs", class = "btn-danger"),
#'                   br(), br(),
#'                   h5("System Information"),
#'                   verbatimTextOutput("system_info")
#'                 )
#'               )
#'             )
#'           )
#'         ),
#'         
#'         easyClose = FALSE
#'       ))
#'       
#'     } else {
#'       shinyalert("Access Denied", "Invalid admin credentials", type = "error")
#'     }
#'   })
#'   
#'   # Admin logout
#'   observeEvent(input$admin_logout, {
#'     admin_logged_in(FALSE)
#'     removeModal()
#'     shinyalert("Admin Logout", "Successfully logged out from admin panel", type = "info")
#'   })
#'   
#'   # Dynamic Stats Cards
#'   output$total_users_stat <- renderUI({
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     
#'     # Count total users from both tables
#'     tryCatch({
#'       students_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM students_enhanced")$count
#'       mentors_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM mentor_profiles")$count
#'       total_users <- students_count + mentors_count
#'     }, error = function(e) {
#'       total_users <- 54  # Fallback number
#'     })
#'     
#'     dbDisconnect(con)
#'     
#'     tagList(
#'       h2(total_users, class = "stats-number"),
#'       p("Total Users", class = "stats-label")
#'     )
#'   })
#'   
#'   output$active_mentors_stat <- renderUI({
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     
#'     tryCatch({
#'       mentors_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM mentor_profiles WHERE active = 1")$count
#'     }, error = function(e) {
#'       mentors_count <- 23  # Fallback number
#'     })
#'     
#'     dbDisconnect(con)
#'     
#'     tagList(
#'       h2(mentors_count, class = "stats-number"),
#'       p("Active Mentors", class = "stats-label")
#'     )
#'   })
#'   
#'   output$students_stat <- renderUI({
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     
#'     tryCatch({
#'       students_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM students_enhanced")$count
#'     }, error = function(e) {
#'       students_count <- 31  # Fallback number
#'     })
#'     
#'     dbDisconnect(con)
#'     
#'     tagList(
#'       h2(students_count, class = "stats-number"),
#'       p("Students", class = "stats-label")
#'     )
#'   })
#'   
#'   output$match_rate_stat <- renderUI({
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     
#'     tryCatch({
#'       total_students <- dbGetQuery(con, "SELECT COUNT(*) as count FROM students_enhanced")$count
#'       matched_students <- dbGetQuery(con, "SELECT COUNT(*) as count FROM students_enhanced WHERE matched_mentor_id IS NOT NULL")$count
#'       
#'       if (total_students > 0) {
#'         match_rate <- round((matched_students / total_students) * 100)
#'       } else {
#'         match_rate <- 95  # Fallback percentage
#'       }
#'     }, error = function(e) {
#'       match_rate <- 95  # Fallback percentage
#'     })
#'     
#'     dbDisconnect(con)
#'     
#'     tagList(
#'       h2(paste0(match_rate, "%"), class = "stats-number"),
#'       p("Match Rate", class = "stats-label")
#'     )
#'   })
#'   
#'   # Analytics Output Functions
#'   output$user_growth_chart <- renderPlotly({
#'     # Sample data for user growth over time
#'     dates <- seq(as.Date("2024-01-01"), Sys.Date(), by = "month")
#'     users <- cumsum(c(5, sample(2:8, length(dates)-1, replace = TRUE)))
#'     
#'     df <- data.frame(
#'       Date = dates,
#'       Users = users
#'     )
#'     
#'     p <- ggplot(df, aes(x = Date, y = Users)) +
#'       geom_line(color = "#4f8bb8", size = 2) +
#'       geom_point(color = "#69b7d1", size = 3) +
#'       theme_minimal() +
#'       labs(title = "User Growth Over Time", x = "Date", y = "Total Users") +
#'       theme(
#'         plot.title = element_text(hjust = 0.5, size = 14, color = "#2c3e50"),
#'         axis.text = element_text(color = "#6c757d"),
#'         panel.grid.minor = element_blank()
#'       )
#'     
#'     ggplotly(p, tooltip = c("x", "y"))
#'   })
#'   
#'   output$success_rate_chart <- renderPlotly({
#'     # Sample data for match success rate
#'     months <- format(seq(as.Date("2024-01-01"), Sys.Date(), by = "month"), "%b %Y")
#'     success_rates <- c(85, 88, 92, 89, 94, 91, 95, 93, 96, 94, 97, 95)[1:length(months)]
#'     
#'     df <- data.frame(
#'       Month = factor(months, levels = months),
#'       Success_Rate = success_rates
#'     )
#'     
#'     p <- ggplot(df, aes(x = Month, y = Success_Rate)) +
#'       geom_col(fill = "#52c3a4", alpha = 0.8) +
#'       geom_text(aes(label = paste0(Success_Rate, "%")), vjust = -0.5, color = "#2c3e50") +
#'       theme_minimal() +
#'       labs(title = "Monthly Match Success Rate", x = "Month", y = "Success Rate (%)") +
#'       ylim(0, 100) +
#'       theme(
#'         plot.title = element_text(hjust = 0.5, size = 14, color = "#2c3e50"),
#'         axis.text.x = element_text(angle = 45, hjust = 1, color = "#6c757d"),
#'         axis.text.y = element_text(color = "#6c757d"),
#'         panel.grid.minor = element_blank()
#'       )
#'     
#'     ggplotly(p, tooltip = c("x", "y"))
#'   })
#'   
#'   output$industry_chart <- renderPlotly({
#'     # Sample data for popular industries
#'     industries <- c("Technology", "Healthcare", "Finance", "Education", "Engineering")
#'     counts <- c(25, 18, 15, 12, 8)
#'     
#'     df <- data.frame(
#'       Industry = factor(industries, levels = industries),
#'       Count = counts
#'     )
#'     
#'     p <- ggplot(df, aes(x = reorder(Industry, Count), y = Count)) +
#'       geom_col(fill = "#667eea", alpha = 0.8) +
#'       coord_flip() +
#'       theme_minimal() +
#'       labs(title = "Popular Industries", x = "Industry", y = "Number of Mentors") +
#'       theme(
#'         plot.title = element_text(hjust = 0.5, size = 12, color = "#2c3e50"),
#'         axis.text = element_text(color = "#6c757d", size = 10),
#'         panel.grid.minor = element_blank()
#'       )
#'     
#'     ggplotly(p, tooltip = c("x", "y"))
#'   })
#'   
#'   output$top_mentors_table <- DT::renderDataTable({
#'     # Sample data for top mentors
#'     top_mentors <- data.frame(
#'       Mentor = c("Dr. Sarah Chen", "Prof. Michael Rodriguez", "Sarah Johnson", "David Kim", "Emily Davis"),
#'       Rating = c(4.9, 4.8, 4.7, 4.6, 4.5),
#'       Matches = c(15, 12, 10, 8, 7),
#'       Industry = c("Technology", "Academia", "Healthcare", "Finance", "Engineering")
#'     )
#'     
#'     DT::datatable(top_mentors, 
#'                   options = list(pageLength = 5, dom = 't', searching = FALSE),
#'                   rownames = FALSE) %>%
#'       DT::formatRound(columns = "Rating", digits = 1)
#'   })
#'   
#'   output$recent_activity_table <- DT::renderDataTable({
#'     # Sample data for recent activity
#'     recent_activity <- data.frame(
#'       Time = c("2 min ago", "15 min ago", "1 hour ago", "3 hours ago", "5 hours ago"),
#'       Activity = c("New student registered", "Mentor match created", "Introduction sent", "Profile updated", "New mentor joined"),
#'       User = c("Alex Johnson", "System", "Maria Garcia", "Dr. Chen", "Robert Wilson")
#'     )
#'     
#'     DT::datatable(recent_activity, 
#'                   options = list(pageLength = 5, dom = 't', searching = FALSE),
#'                   rownames = FALSE)
#'   })
#'   
#'   output$all_users_table <- DT::renderDataTable({
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     
#'     # Get users from both students and mentors tables
#'     students <- dbGetQuery(con, "SELECT name, email, 'Student' as role, created_at FROM students_enhanced ORDER BY created_at DESC")
#'     mentors <- dbGetQuery(con, "SELECT name, email, 'Mentor' as role, created_at FROM mentor_profiles ORDER BY created_at DESC")
#'     
#'     if (nrow(students) == 0 && nrow(mentors) == 0) {
#'       # Sample data if no real data exists
#'       all_users <- data.frame(
#'         Name = c("Alex Johnson", "Dr. Sarah Chen", "Maria Garcia", "Prof. Rodriguez", "Emily Davis"),
#'         Email = c("alex@university.edu", "sarah.chen@tech.com", "maria@healthcare.org", "prof.rodriguez@university.edu", "emily@engineering.com"),
#'         Role = c("Student", "Mentor", "Student", "Mentor", "Student"),
#'         Joined = c("2024-12-01", "2024-11-15", "2024-12-10", "2024-10-20", "2024-12-15")
#'       )
#'     } else {
#'       all_users <- rbind(students, mentors)
#'       names(all_users) <- c("Name", "Email", "Role", "Joined")
#'     }
#'     
#'     dbDisconnect(con)
#'     
#'     DT::datatable(all_users, 
#'                   options = list(pageLength = 10, dom = 'Bfrtip'),
#'                   extensions = 'Buttons',
#'                   rownames = FALSE)
#'   })
#'   
#'   output$notification_history_table <- DT::renderDataTable({
#'     # Sample notification history
#'     notifications <- data.frame(
#'       Date = c("2024-12-31", "2024-12-28", "2024-12-25", "2024-12-20"),
#'       Type = c("System Update", "New Feature", "Maintenance", "General"),
#'       Title = c("Platform Upgrade", "AI Improvements", "Scheduled Maintenance", "Welcome Message"),
#'       Recipients = c("All Users", "Students", "All Users", "New Users"),
#'       Status = c("Sent", "Sent", "Sent", "Sent")
#'     )
#'     
#'     DT::datatable(notifications, 
#'                   options = list(pageLength = 5, dom = 't', searching = FALSE),
#'                   rownames = FALSE)
#'   })
#'   
#'   output$system_info <- renderText({
#'     paste(
#'       "R Version:", R.version.string, "\n",
#'       "Platform:", Sys.info()["sysname"], Sys.info()["release"], "\n",
#'       "Database Size:", "45.2 MB", "\n",
#'       "Active Connections:", "127", "\n",
#'       "Uptime:", "2 days, 14 hours", "\n",
#'       "Memory Usage:", "234 MB / 2 GB"
#'     )
#'   })
#'   
#'   # Admin Action Handlers
#'   observeEvent(input$send_notification, {
#'     req(input$notification_title, input$notification_message)
#'     
#'     # Here you would implement the actual notification sending logic
#'     shinyalert("Success!", 
#'                paste("Notification '", input$notification_title, "' sent to", input$notification_target), 
#'                type = "success")
#'   })
#'   
#'   observeEvent(input$export_users, {
#'     shinyalert("Export Started", "User data export has been initiated. You will receive an email when ready.", type = "info")
#'   })
#'   
#'   observeEvent(input$backup_db, {
#'     shinyalert("Backup Started", "Database backup initiated. This may take a few minutes.", type = "info")
#'   })
#'   
#'   observeEvent(input$test_email, {
#'     shinyalert("Email Test", "Test email sent successfully! Check your inbox.", type = "success")
#'   })
#'   
#'   observeEvent(input$save_smtp, {
#'     shinyalert("Settings Saved", "SMTP configuration has been saved successfully.", type = "success")
#'   })
#'     # Render results section
#'   output$results_section <- renderUI({
#'     req(matches())
#'     
#'  
#'       
#'       showModal(modalDialog(
#'         title = div(
#'           style = "background: linear-gradient(135deg, var(--bs-primary) 0%, var(--bs-secondary) 100%); 
#'                    color: white; padding: 20px; margin: -15px -15px 20px -15px; 
#'                    border-radius: 15px 15px 0 0; text-align: center;",
#'           h3("🎯 Your Perfect Mentor Matches", 
#'              style = "margin: 0; font-weight: 600;"),
#'           p("Choose a mentor that best fits your goals and interests", 
#'             style = "margin: 10px 0 0 0; opacity: 0.9; font-size: 16px;")
#'         ),
#'                  size = "xl",
#'          easyClose = TRUE,
#'          
#'          # Modal content with mentor cards in a grid
#'          div(
#'            style = "max-height: 70vh; overflow-y: auto; padding: 10px;",
#'            
#'            # Grid layout for mentor cards (smaller cards for modal)
#'            div(
#'              style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 15px;",
#'              lapply(seq_along(matches()), function(i) {
#'                               mentor <- matches()[[i]]
#'                               
#'                               # Smaller mentor card for modal
#'                               card(
#'                                 class = "mentor-match-card",
#'                                 style = "cursor: pointer; height: 300px; position: relative; overflow: hidden; 
#'                                          transition: all 0.3s ease; border: 1px solid #e0e0e0;",
#'                                 onclick = paste0("Shiny.setInputValue('mentor_card_clicked', ", mentor$id, ", {priority: 'event'})"),
#'                                 
#'                                 card_body(
#'                                   style = "text-align: center; padding: 15px; height: 100%; display: flex; flex-direction: column;",
#'                                   
#'                                   # Profile Image with Score Badge
#'                                   div(
#'                                     style = "position: relative; margin-bottom: 12px;",
#'                                     img(src = {
#'                                       img_src <- NULL
#'                                       if (!is.null(mentor$profile_image) && !is.na(mentor$profile_image) && nchar(mentor$profile_image) > 0) {
#'                                         img_src <- mentor$profile_image
#'                                       } else if (!is.null(mentor$image) && !is.na(mentor$image) && nchar(mentor$image) > 0) {
#'                                         img_src <- mentor$image
#'                                       } else {
#'                                         img_src <- "https://via.placeholder.com/70x70?text=M"
#'                                       }
#'                                       img_src
#'                                     }, 
#'                                     style = "width: 70px; height: 70px; border-radius: 50%; border: 3px solid var(--bs-primary); 
#'                                              object-fit: cover; box-shadow: 0 2px 10px rgba(0,0,0,0.1);",
#'                                     onerror = "this.src='https://via.placeholder.com/70x70?text=M'"),
#'                                     
#'                                     # Compatibility Score Badge
#'                                     div(
#'                                       style = "position: absolute; top: -5px; right: 5px; z-index: 10;",
#'                                       span(
#'                                         paste0("🎯 ", round(mentor$score * 100), "%"),
#'                                         style = "background: linear-gradient(135deg, #28a745 0%, #20c997 100%); 
#'                                                  color: white; padding: 4px 8px; border-radius: 12px; 
#'                                                  font-weight: 600; font-size: 0.7rem; box-shadow: 0 2px 8px rgba(40,167,69,0.3);"
#'                                       )
#'                                     )
#'                                   ),
#'                                   
#'                                   # Mentor Details
#'                                   div(
#'                                     style = "flex-grow: 1;",
#'                                     h5(mentor$name, 
#'                                        style = "color: var(--bs-dark); margin-bottom: 4px; font-weight: 600; font-size: 1rem;"),
#'                                     h6(mentor$title, 
#'                                        style = "color: var(--bs-secondary); margin-bottom: 10px; font-size: 0.85rem; opacity: 0.8;"),
#'                                     
#'                                     # Expertise Preview (shorter for modal)
#'                                     div(
#'                                       style = "margin-bottom: 10px;",
#'                                       p(strong("Expertise: "), 
#'                                         style = "color: var(--bs-dark); font-size: 0.8rem; margin-bottom: 4px;"),
#'                                       p({
#'                                         expertise_text <- if (!is.null(mentor$expertise) && !is.na(mentor$expertise) && nchar(mentor$expertise) > 0) {
#'                                           mentor$expertise
#'                                         } else {
#'                                           "No expertise information available"
#'                                         }
#'                                         if(!is.null(expertise_text) && !is.na(expertise_text) && nchar(expertise_text) > 50) {
#'                                           paste0(substr(expertise_text, 1, 50), "...")
#'                                         } else {
#'                                           expertise_text
#'                                         }
#'                                       },
#'                                       style = "font-size: 0.75rem; color: #6c757d; line-height: 1.2; margin-bottom: 0;")
#'                                     )
#'                                   ),
#'                                   
#'                                   # Click to Connect CTA
#'                                   div(
#'                                     style = "margin-top: auto;",
#'                                     div(
#'                                       style = "border: 2px dashed var(--bs-primary); border-radius: 8px; 
#'                                                padding: 8px; background: rgba(102, 126, 234, 0.05);",
#'                                       p("👆 Click to view full profile", 
#'                                         style = "font-size: 0.7rem; color: var(--bs-primary); margin: 0; font-weight: 600;"),
#'                                       p("and connect!", 
#'                                         style = "font-size: 0.65rem; color: #6c757d; margin: 2px 0 0 0;")
#'                                     )
#'                                   )
#'                                 )
#'                               )
#'                             })
#'            )
#'          ),
#'          
#'          footer = div(
#'            class = "text-center",
#'            actionButton("back_to_search", "← Search Again", class = "btn-outline-primary")
#'          )
#'       ))
#'     
#'   })
#'    
#'   # Handle back to search
#'   observeEvent(input$back_to_search, {
#'     matches(NULL)
#'   })
#'   
#'   # Handle mentor card clicks
#'   observeEvent(input$mentor_card_clicked, {
#'     mentor_id <- input$mentor_card_clicked
#'     found_mentor <- NULL
#'     
#'     if (!is.null(matches())) {
#'       for (mentor in matches()) {
#'         if (mentor$id == mentor_id) {
#'           found_mentor <- mentor
#'           break
#'         }
#'       }
#'     }
#'     
#'     if (!is.null(found_mentor)) {
#'       selected_mentor(found_mentor)
#'       
#'       showModal(modalDialog(
#'         title = NULL,
#'         size = "l",
#'         
#'         # Header with mentor info
#'         div(
#'           style = "background: var(--primary-gradient); 
#'                    color: white; padding: 30px; margin: -15px -15px 20px -15px; border-radius: 15px 15px 0 0;",
#'           layout_columns(
#'             col_widths = c(3, 9),
#'             div(
#'               class = "text-center",
#'               img(src = {
#'                 modal_img_src <- NULL
#'                 if (!is.null(found_mentor$profile_image) && !is.na(found_mentor$profile_image) && nchar(found_mentor$profile_image) > 0) {
#'                   modal_img_src <- found_mentor$profile_image
#'                 } else if (!is.null(found_mentor$image) && !is.na(found_mentor$image) && nchar(found_mentor$image) > 0) {
#'                   modal_img_src <- found_mentor$image
#'                 } else {
#'                   modal_img_src <- "https://via.placeholder.com/100x100?text=M"
#'                 }
#'                 modal_img_src
#'               }, 
#'                   style = "width: 100px; height: 100px; border-radius: 50%; border: 4px solid white;",
#'                   onerror = "this.src='https://via.placeholder.com/100x100?text=M'")
#'             ),
#'             div(
#'               h3(found_mentor$name, style = "margin-bottom: 5px; font-weight: 600;"),
#'               h5(found_mentor$title, style = "opacity: 0.9; margin-bottom: 15px;"),
#'               span(
#'                 paste0("🎯 ", round(found_mentor$score * 100), "% Compatibility Match"),
#'                 style = "background: rgba(255,255,255,0.2); border-radius: 20px; padding: 8px 15px; font-weight: 600;"
#'               )
#'             )
#'           )
#'         ),
#'         
#'         # Content
#'         h4("🎯 Expertise & Specializations"),
#'         p(if (!is.null(found_mentor$expertise) && !is.na(found_mentor$expertise) && nchar(found_mentor$expertise) > 0) {
#'           found_mentor$expertise
#'         } else {
#'           "No expertise information available"
#'         }),
#'         
#'         h4("📖 Professional Background"),
#'         p(if (!is.null(found_mentor$bio) && !is.na(found_mentor$bio) && nchar(found_mentor$bio) > 0) {
#'           found_mentor$bio
#'         } else {
#'           "No biography available"
#'         }),
#'         
#'         h4("💌 Ready to Connect?"),
#'         p("Send a personalized introduction message to start your mentoring journey!"),
#'         
#'         textAreaInput("intro_message", "Your Message", 
#'                      height = "120px",
#'                      placeholder = paste0("Hi ", found_mentor$name, "! I found your profile through MentorMatch AI and I'm really interested in connecting because...")),
#'         
#'         footer = tagList(
#'           modalButton("✕"),
#'           actionButton("send_intro", "📧 Send Introduction", class = "btn-primary btn-lg")
#'         )
#'       ))
#'     }
#'   })
#'   
#'   # Handle sending introduction email
#'   observeEvent(input$send_intro, {
#'     req(selected_mentor(), student_data$id)
#'     
#'     con <- dbConnect(RSQLite::SQLite(), "mentormatch_enhanced.sqlite")
#'     student <- student_data
#'     mentor <- selected_mentor()
#'     
#'     # Create message
#'     message_text <- if (nchar(trimws(input$intro_message)) > 0) {
#'       input$intro_message
#'     } else {
#'       paste0("Hello! I found your profile through MentorMatch AI and I'm interested in connecting. ",
#'              "I'm studying ", student$major, " and interested in ", student$career_interest, ". ",
#'              "My biggest challenge right now is: ", student$challenge)
#'     }
#'     
#'     # Send emails using enhanced email utils
#'     tryCatch({
#'       if (SMTP_CONFIG$username != "your-email@gmail.com") {
#'         # Use SMTP
#'         send_smtp_email(
#'           to = mentor$email,
#'           subject = paste("MentorMatchAI: New Mentee Match -", student$name),
#'           body = paste0("Hello ", mentor$name, ",\n\n",
#'                        "You have been selected as a mentor by ", student$name, ".\n\n",
#'                        "Student's message:\n", message_text, "\n\n",
#'                        "Student's email: ", student$email, "\n\n",
#'                        "Please respond directly to the student's email.\n\n",
#'                        "Best regards,\nMentorMatch AI Team")
#'         )
#'         
#'         send_smtp_email(
#'           to = student$email,
#'           subject = "MentorMatchAI: Mentor Match Confirmation",
#'           body = paste0("Congratulations ", student$name, "!\n\n",
#'                        "Your introduction email to ", mentor$name, " has been sent.\n\n",
#'                        "You should hear back from them within 24-48 hours.\n\n",
#'                        "Good luck with your mentoring journey!\n\n",
#'                        "- The MentorMatchAI Team")
#'         )
#'       } else {
#'         # Fallback to console mode
#'         source("email_utils.R")
#'         send_email_to_mentor(
#'           student_name = student$name,
#'           student_email = student$email,
#'           mentor_email = mentor$email,
#'           mentor_name = mentor$name,
#'           mentor_message = message_text
#'         )
#'         
#'         send_confirmation_to_student(
#'           student_name = student$name,
#'           student_email = student$email,
#'           mentor_name = mentor$name,
#'           timestamp = Sys.time()
#'         )
#'       }
#'     }, error = function(e) {
#'       cat("Email error:", e$message, "\n")
#'     })
#'     
#'     # Update database
#'     dbExecute(con, "UPDATE students SET matched_mentor_id = ? WHERE id = ?", 
#'               params = list(mentor$id, student_data$id))
#'     
#'     removeModal()
#'     
#'     showModal(modalDialog(
#'       title = "🎉 Introduction Sent!",
#'       div(
#'         class = "text-center",
#'         h4("Success!"),
#'         p(paste0("Your introduction has been sent to ", mentor$name, "!")),
#'         div(
#'           style = "background: var(--success-gradient); 
#'                    color: white; padding: 20px; border-radius: 10px; margin: 20px 0;",
#'           h5("📧 What happens next?"),
#'           p("You'll receive a confirmation email, and ", mentor$name, " will get your introduction message."),
#'           p("Most mentors respond within 24-48 hours!")
#'         ),
#'         p("🌟 Good luck with your mentoring journey!", style = "color: var(--bs-primary); font-weight: 600;")
#'       ),
#'       easyClose = TRUE,
#'       footer = tagList(
#'         actionButton("intro_sent_ok", "🎯 Find More Mentors", class = "btn-primary"),
#'         actionButton("intro_sent_done", "✅ All Done", class = "btn-success")
#'       )
#'     ))
#'     
#'     dbDisconnect(con)
#'   })
#'   
#'   observeEvent(input$intro_sent_ok, {
#'     removeModal()
#'   })
#'   
#'   observeEvent(input$intro_sent_done, {
#'     removeModal()
#'     matches(NULL)
#'   })
#' }
#' 
#'   # Create enhanced app
#' shinyApp(ui, server) 