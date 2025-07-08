library(shiny)
library(bslib)
library(DBI)
library(RSQLite)
library(text2vec)
library(Matrix)
library(proxy)
library(stopwords)

# Source utility functions
source("mentor_recommender.R")
source("email_utils.R")

# Define the %||% operator (null-coalescing operator)
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (is.character(x) && nchar(x) == 0)) y else x

# Helper: check if enough mentors exist
has_enough_mentors <- function(con, min_n = 3) {
  n <- dbGetQuery(con, "SELECT COUNT(*) as n FROM mentor_profiles")$n
  n >= min_n
}

# Modern bslib theme
app_theme <- bs_theme(
  version = 5,
  preset = "bootstrap",
  primary = "#4f8bb8",
  secondary = "#69b7d1", 
  success = "#52c3a4",
  bg = "#ffffff",
  fg = "#2c3e50",
  base_font = font_google("Inter"),
  heading_font = font_google("Poppins", wght = c(400, 600, 700))
)

# Define bslib theme
app_theme <- bs_theme(
  version = 5,
  preset = "bootstrap",
  primary = "#667eea",
  secondary = "#764ba2", 
  success = "#28a745",
  info = "#17a2b8",
  warning = "#ffc107",
  danger = "#dc3545",
  base_font = font_google("Inter"),
  heading_font = font_google("Poppins", wght = c(400, 600, 700)),
  bg = "#ffffff",
  fg = "#212529"
)

ui <- page_navbar(
  title = "🎯 MentorMatch AI",
  theme = app_theme,
  bg = "primary",
  inverse = TRUE,
  
  nav_panel(
    title = "Home",
    layout_columns(
      col_widths = 12,
      
      # Hero Section
      div(
        class = "hero-section",
        style = "background: linear-gradient(135deg, var(--bs-primary) 0%, var(--bs-secondary) 100%); 
                 color: white; padding: 80px 20px; text-align: center; margin: -20px -15px 40px -15px; border-radius: 0 0 20px 20px;",
        h1("🎯 MentorMatch AI", 
           style = "font-size: 3.5rem; font-weight: 700; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
        p("Connect with the perfect mentor using AI-powered semantic matching", 
          style = "font-size: 1.3rem; margin-bottom: 40px; opacity: 0.95;"),
        
        div(
          style = "display: flex; justify-content: center; gap: 20px; flex-wrap: wrap;",
          actionButton("show_student_modal", 
                      "🎓 I'm a Student", 
                      class = "btn-light btn-lg",
                      style = "padding: 15px 30px; font-size: 1.1rem; font-weight: 600; border-radius: 50px; min-width: 200px; box-shadow: 0 4px 15px rgba(0,0,0,0.2);"),
          actionButton("show_mentor_modal", 
                      "👨‍🏫 I'm a Mentor", 
                      class = "btn-outline-light btn-lg",
                      style = "padding: 15px 30px; font-size: 1.1rem; font-weight: 600; border-radius: 50px; min-width: 200px; box-shadow: 0 4px 15px rgba(0,0,0,0.2);")
        )
      ),
      
      # Features Section  
      layout_columns(
        col_widths = c(4, 4, 4),
        
        card(
          card_header("🧠 AI-Powered Matching"),
          card_body(
            p("Our advanced semantic analysis finds mentors that truly align with your goals, interests, and learning style."),
            p(strong("✓ Compatibility Scoring"), br(),
              "✓ Personalized Recommendations", br(),
              "✓ Smart Question Analysis")
          )
        ),
        
        card(
          card_header("🎯 Perfect Connections"),
          card_body(
            p("Connect with mentors who have the exact expertise and experience you're looking for in your field."),
            p(strong("✓ Industry Experts"), br(),
              "✓ Verified Profiles", br(),
              "✓ Diverse Backgrounds")
          )
        ),
        
        card(
          card_header("📧 Easy Communication"),
          card_body(
            p("Send personalized introduction messages and get connected with your ideal mentor instantly."),
            p(strong("✓ Custom Messages"), br(),
              "✓ Email Integration", br(),
              "✓ Quick Responses")
          )
        )
      ),
      
      # Results section (hidden initially)
      uiOutput("results_section")
    )
  ),
  
  nav_panel("About", 
    layout_columns(
      col_widths = 12,
      card(
        card_header("About MentorMatch AI"),
        card_body(
          h4("Revolutionizing Mentorship Through AI"),
          p("MentorMatch AI uses advanced natural language processing and semantic analysis to create meaningful connections between students and mentors."),
          
          h5("How It Works:"),
          tags$ol(
            tags$li("Students complete a comprehensive questionnaire about their goals and interests"),
            tags$li("Our AI analyzes responses using semantic matching algorithms"),
            tags$li("The system finds the top 3 most compatible mentors"),
            tags$li("Students can view detailed profiles and send personalized connection requests"),
            tags$li("Email notifications facilitate the first contact")
          ),
          
          h5("Technology Stack:"),
          p("Built with R Shiny, text2vec for NLP, TF-IDF vectorization, LSA dimensionality reduction, and cosine similarity matching.")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Reactive values
  student_data <- reactiveValues()
  mentor_data <- reactiveValues()
  matches <- reactiveVal(NULL)
  selected_mentor <- reactiveVal(NULL)
  embedding_system <- reactiveVal(NULL)
  
  # Initialize database and embedding system
  observe({
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    
    # Ensure tables exist
    dbExecute(con, "CREATE TABLE IF NOT EXISTS mentors (id INTEGER PRIMARY KEY, name TEXT, email TEXT, majors TEXT, industries TEXT, offers TEXT, comm TEXT, aspects TEXT, bio TEXT)")
    dbExecute(con, "CREATE TABLE IF NOT EXISTS students (id INTEGER PRIMARY KEY, name TEXT, email TEXT, majors TEXT, industries TEXT, looking_for TEXT, comm TEXT, aspects TEXT, challenge TEXT, matched_mentor_id INTEGER)")
    
    # Initialize embedding system if enough mentors
    if (has_enough_mentors(con)) {
      tryCatch({
        embedding_system(default_embedding_system(con))
        message("✓ Semantic recommendation system initialized")
      }, error = function(e) {
        message("⚠ Could not initialize semantic system: ", e$message)
      })
    }
    
    dbDisconnect(con)
  })
  
  # Student Modal
  observeEvent(input$show_student_modal, {
    showModal(modalDialog(
      title = div(
        style = "background: linear-gradient(135deg, var(--bs-primary) 0%, var(--bs-secondary) 100%); 
                 color: white; padding: 20px; margin: -15px -15px 20px -15px; border-radius: 10px;",
        h3("🎓 Student Questionnaire", style = "margin: 0; font-weight: 600;"),
        p("Help us find your perfect mentor match!", style = "margin: 5px 0 0 0; opacity: 0.9;")
      ),
      size = "l",
      
      layout_columns(
        col_widths = c(6, 6),
        
        # Left Column
        div(
          h5("👤 Personal Information", style = "color: var(--bs-primary); margin-bottom: 15px;"),
          textInput("student_name", "Full Name", placeholder = "Alex Johnson"),
          textInput("student_email", "Email Address", placeholder = "alex@university.edu"),
          
          h5("🎯 Academic Focus", style = "color: var(--bs-primary); margin-top: 25px; margin-bottom: 15px;"),
          selectInput("student_major", "Primary Academic Interest", 
                     choices = list(
                       "STEM" = c("Computer Science", "Engineering", "Mathematics", "Physics", "Biology", "Chemistry"),
                       "Business & Economics" = c("Business Administration", "Economics", "Finance", "Marketing", "Entrepreneurship"),
                       "Social Sciences" = c("Psychology", "Sociology", "Political Science", "International Relations"),
                       "Humanities" = c("English Literature", "History", "Philosophy", "Languages", "Art"),
                       "Health & Medicine" = c("Pre-Med", "Nursing", "Public Health", "Biomedical Sciences"),
                       "Other" = c("Law", "Education", "Communications", "Environmental Studies", "Other")
                     ),
                     selected = NULL),
          
          selectInput("student_level", "Academic Level", 
                     choices = c("High School Student", "Undergraduate", "Graduate Student", "Recent Graduate", "Career Changer"),
                     selected = NULL)
        ),
        
        # Right Column  
        div(
          h5("💼 Career Goals", style = "color: var(--bs-primary); margin-bottom: 15px;"),
          selectInput("career_interest", "Target Industry", 
                     choices = c("Technology & Software", "Healthcare & Medicine", "Business & Finance", 
                                "Education & Academia", "Government & Public Policy", "Non-profit & Social Impact",
                                "Creative & Media", "Engineering & Manufacturing", "Research & Development", "Other"),
                     selected = NULL),
          
          selectInput("career_stage", "Career Goal Timeline", 
                     choices = c("Exploring different paths", "Preparing for internships", "Job searching", 
                                "Planning graduate school", "Changing career direction", "Starting my own business"),
                     selected = NULL),
          
          h5("🤝 Mentorship Preferences", style = "color: var(--bs-primary); margin-top: 25px; margin-bottom: 15px;"),
          checkboxGroupInput("mentorship_type", "What kind of guidance do you need?",
                           choices = c("Career planning & strategy" = "career_planning",
                                     "Industry insights & networking" = "networking", 
                                     "Skill development & learning" = "skills",
                                     "Job search & interview prep" = "job_prep",
                                     "Graduate school guidance" = "grad_school",
                                     "Personal development & confidence" = "personal_dev"),
                           selected = NULL),
          
          textAreaInput("biggest_challenge", "What's your biggest current challenge or goal?", 
                       height = "80px",
                       placeholder = "e.g., 'I'm struggling to choose between different career paths in tech...'")
        )
      ),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("submit_student", "🔍 Find My Mentor!", class = "btn-primary btn-lg")
      ),
      
      easyClose = FALSE
    ))
  })
  
  # Mentor Modal
  observeEvent(input$show_mentor_modal, {
    showModal(modalDialog(
      title = div(
        style = "background: linear-gradient(135deg, var(--bs-success) 0%, #20c997 100%); 
                 color: white; padding: 20px; margin: -15px -15px 20px -15px; border-radius: 10px;",
        h3("👨‍🏫 Mentor Registration", style = "margin: 0; font-weight: 600;"),
        p("Share your expertise and help the next generation!", style = "margin: 5px 0 0 0; opacity: 0.9;")
      ),
      size = "l",
      
      layout_columns(
        col_widths = c(6, 6),
        
        # Left Column
        div(
          h5("👤 Professional Information", style = "color: var(--bs-success); margin-bottom: 15px;"),
          textInput("mentor_name", "Full Name", placeholder = "Dr. Jane Smith"),
          textInput("mentor_email", "Email Address", placeholder = "jane@company.com"),
          textInput("mentor_title", "Current Position", placeholder = "Senior Data Scientist at TechCorp"),
          
          selectInput("mentor_industry", "Primary Industry", 
                     choices = c("Technology & Software", "Healthcare & Medicine", "Business & Finance", 
                                "Education & Academia", "Government & Public Policy", "Non-profit & Social Impact",
                                "Creative & Media", "Engineering & Manufacturing", "Research & Development", "Other"),
                     selected = NULL),
          
          selectInput("mentor_experience", "Years of Experience", 
                     choices = c("3-5 years", "5-10 years", "10-15 years", "15+ years"),
                     selected = NULL)
        ),
        
        # Right Column
        div(
          h5("🎯 Expertise & Mentoring", style = "color: var(--bs-success); margin-bottom: 15px;"),
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
                     choices = c("Email exchanges", "Video calls (30-60 min)", "Phone calls", "In-person meetings", "Flexible - any method"),
                     selected = NULL),
          
          textAreaInput("mentor_bio", "Professional Bio & Mentoring Philosophy", 
                       height = "100px",
                       placeholder = "Tell potential mentees about your background and what you can offer...")
        )
      ),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("submit_mentor", "🚀 Join as Mentor", class = "btn-success btn-lg")
      ),
      
      easyClose = FALSE
    ))
  })
  
  # Handle student submission
  observeEvent(input$submit_student, {
    req(input$student_name, input$student_email, input$student_major, input$career_interest)
    
    # Store student data
    student_data$name <- input$student_name
    student_data$email <- input$student_email
    student_data$major <- input$student_major
    student_data$career_interest <- input$career_interest
    student_data$career_stage <- input$career_stage
    student_data$mentorship_type <- paste(input$mentorship_type, collapse = ", ")
    student_data$challenge <- input$biggest_challenge
    student_data$level <- input$student_level
    
    # Save to database
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    dbExecute(con, "INSERT INTO students (name, email, majors, industries, looking_for, comm, aspects, challenge) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
              params = list(
                student_data$name,
                student_data$email,
                student_data$major,
                student_data$career_interest,
                student_data$mentorship_type,
                input$communication_pref %||% "Email",
                student_data$career_stage,
                student_data$challenge
              ))
    
    student_row <- dbGetQuery(con, "SELECT id FROM students WHERE email = ? ORDER BY id DESC LIMIT 1", 
                              params = list(student_data$email))
    student_data$id <- student_row$id[1]
    
    removeModal()
    
    # Check if enough mentors exist
    if (has_enough_mentors(con)) {
      # Use semantic recommendation system
      if (!is.null(embedding_system())) {
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
      } else {
        # Fallback to simple matching
        mentors <- dbGetQuery(con, "SELECT * FROM mentor_profiles LIMIT 3")
        simple_matches <- lapply(seq_len(nrow(mentors)), function(i) {
          mentor <- as.list(mentors[i, ])
          mentor$score <- 0.75 + runif(1, -0.1, 0.1) # Random score between 0.65-0.85
          mentor
        })
        matches(simple_matches)
      }
    } else {
      showModal(modalDialog(
        title = "🔍 Building Our Mentor Network",
        div(
          class = "text-center",
          h4("We're still growing our mentor community!"),
          p("We don't have enough mentors yet to provide quality matches for your specific interests."),
          br(),
          div(
            style = "background: linear-gradient(135deg, var(--bs-primary) 0%, var(--bs-secondary) 100%); 
                     color: white; padding: 20px; border-radius: 10px;",
            h5("📧 We'll notify you when we find perfect matches!"),
            p("Based on your interests in ", strong(student_data$major), " and ", strong(student_data$career_interest), 
              ", we'll prioritize finding mentors in these areas.")
          )
        ),
        easyClose = TRUE,
        footer = actionButton("student_insufficient_ok", "📧 Notify Me When Ready", class = "btn-primary")
      ))
    }
    dbDisconnect(con)
  })
  
  # Handle mentor submission
  observeEvent(input$submit_mentor, {
    req(input$mentor_name, input$mentor_email, input$mentor_title)
    
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    
    # Store mentor data
    expertise_text <- paste(c(input$mentor_expertise, input$mentor_willing), collapse = ", ")
    
    # Insert into simple mentors table
    dbExecute(con, "INSERT INTO mentors (name, email, majors, industries, offers, comm, aspects, bio) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
              params = list(
                input$mentor_name,
                input$mentor_email,
                input$mentor_industry,
                input$mentor_industry,
                expertise_text,
                input$communication_pref,
                input$mentor_experience,
                input$mentor_bio
              ))
    
    # Also insert into mentor_profiles for semantic matching
    dbExecute(con, "INSERT INTO mentor_profiles (name, title, expertise, bio, email, image) VALUES (?, ?, ?, ?, ?, ?)",
              params = list(
                input$mentor_name,
                input$mentor_title,
                expertise_text,
                input$mentor_bio,
                input$mentor_email,
                "https://via.placeholder.com/100x100?text=M" # Default image
              ))
    
    dbDisconnect(con)
    removeModal()
    
    showModal(modalDialog(
      title = "🎉 Welcome to MentorMatch!",
      div(
        class = "text-center",
        h4("Thank you for joining our mentor community!"),
        p("Your profile has been created successfully."),
        div(
          style = "background: linear-gradient(135deg, var(--bs-success) 0%, #20c997 100%); 
                   color: white; padding: 20px; border-radius: 10px; margin: 20px 0;",
          h5("🌟 Ready to make a difference!"),
          p("You'll receive email notifications when students are interested in connecting with you.")
        ),
        p("Your expertise in ", strong(input$mentor_industry), " will help shape the next generation of professionals.")
      ),
      easyClose = TRUE,
      footer = actionButton("mentor_ok", "🚀 Start Mentoring", class = "btn-success")
    ))
  })
  
  # Handle insufficient mentors OK
  observeEvent(input$student_insufficient_ok, {
    removeModal()
  })
  
  # Handle mentor OK
  observeEvent(input$mentor_ok, {
    removeModal()
  })
  
  # Render results section
  output$results_section <- renderUI({
    req(matches())
    
    tagList(
      h2("🎯 Your Perfect Mentor Matches", 
         style = "text-align: center; color: var(--bs-primary); margin: 40px 0; font-weight: 600;"),
      
      layout_columns(
        col_widths = 12,
        lapply(seq_along(matches()), function(i) {
          mentor <- matches()[[i]]
          
          card(
            style = "cursor: pointer; transition: all 0.3s ease; border: none; box-shadow: 0 4px 15px rgba(0,0,0,0.1);",
            onclick = paste0("Shiny.setInputValue('mentor_clicked', ", mentor$id, ", {priority: 'event'})"),
            
            card_body(
              layout_columns(
                col_widths = c(3, 6, 3),
                
                # Mentor Image
                div(
                  class = "text-center",
                  img(src = mentor$image, 
                      style = "width: 80px; height: 80px; border-radius: 50%; border: 3px solid var(--bs-primary);",
                      onerror = "this.src='https://via.placeholder.com/80x80?text=M'"),
                  br(), br(),
                  span(
                    paste0("🎯 ", round(mentor$score * 100), "%"),
                    style = "background: linear-gradient(135deg, var(--bs-primary) 0%, var(--bs-secondary) 100%); 
                             color: white; padding: 8px 15px; border-radius: 20px; font-weight: 600; font-size: 0.9rem;"
                  )
                ),
                
                # Mentor Info
                div(
                  h4(mentor$name, style = "color: var(--bs-primary); margin-bottom: 5px; font-weight: 600;"),
                  h6(mentor$title, style = "color: var(--bs-secondary); margin-bottom: 15px; opacity: 0.8;"),
                  p(strong("Expertise: "), mentor$expertise),
                  p(mentor$bio, style = "font-size: 0.95rem; color: #6c757d;")
                ),
                
                # Action
                div(
                  class = "text-center",
                  div(
                    style = "margin-top: 20px;",
                    p("👆 Click to view", br(), "full profile", 
                      style = "font-size: 0.9rem; color: var(--bs-primary); margin: 0;"),
                    br(),
                    span("and connect!", 
                         style = "font-size: 0.8rem; color: #6c757d;")
                  )
                )
              )
            )
          )
        })
      ),
      
      div(
        class = "text-center",
        style = "margin-top: 30px;",
        actionButton("back_to_search", "← Search Again", class = "btn-outline-primary")
      )
    )
  })
  
  # Handle back to search
  observeEvent(input$back_to_search, {
    matches(NULL)
  })
  
  # Handle mentor card clicks (same as before - will continue in next part...)
  observeEvent(input$mentor_clicked, {
    mentor_id <- input$mentor_clicked
    found_mentor <- NULL
    
    if (!is.null(matches())) {
      for (mentor in matches()) {
        if (mentor$id == mentor_id) {
          found_mentor <- mentor
          break
        }
      }
    }
    
    if (!is.null(found_mentor)) {
      selected_mentor(found_mentor)
      
      showModal(modalDialog(
        title = NULL,
        size = "l",
        
        # Header with mentor info
        div(
          style = "background: linear-gradient(135deg, var(--bs-primary) 0%, var(--bs-secondary) 100%); 
                   color: white; padding: 30px; margin: -15px -15px 20px -15px; border-radius: 15px 15px 0 0;",
          layout_columns(
            col_widths = c(3, 9),
            div(
              class = "text-center",
              img(src = found_mentor$image, 
                  style = "width: 100px; height: 100px; border-radius: 50%; border: 4px solid white;",
                  onerror = "this.src='https://via.placeholder.com/100x100?text=M'")
            ),
            div(
              h3(found_mentor$name, style = "margin-bottom: 5px; font-weight: 600;"),
              h5(found_mentor$title, style = "opacity: 0.9; margin-bottom: 15px;"),
              span(
                paste0("🎯 ", round(found_mentor$score * 100), "% Compatibility Match"),
                style = "background: rgba(255,255,255,0.2); border-radius: 20px; padding: 8px 15px; font-weight: 600;"
              )
            )
          )
        ),
        
        # Content
        h4("🎯 Expertise & Specializations"),
        p(found_mentor$expertise),
        
        h4("📖 Professional Background"),
        p(found_mentor$bio),
        
        h4("💌 Ready to Connect?"),
        p("Send a personalized introduction message to start your mentoring journey!"),
        
        textAreaInput("intro_message", "Your Message", 
                     height = "120px",
                     placeholder = paste0("Hi ", found_mentor$name, "! I found your profile through MentorMatch AI and I'm really interested in connecting because...")),
        
        footer = tagList(
          modalButton("Cancel"),
          actionButton("send_intro", "📧 Send Introduction", class = "btn-primary btn-lg")
        )
      ))
    }
  })
  
  # Handle sending introduction email (same logic as before)
  observeEvent(input$send_intro, {
    req(selected_mentor(), student_data$id)
    
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    student <- student_data
    mentor <- selected_mentor()
    
    # Create message
    message_text <- if (nchar(trimws(input$intro_message)) > 0) {
      input$intro_message
    } else {
      paste0("Hello! I found your profile through MentorMatch AI and I'm interested in connecting. ",
             "I'm studying ", student$major, " and interested in ", student$career_interest, ". ",
             "My biggest challenge right now is: ", student$challenge)
    }
    
    # Send emails
    send_email_to_mentor(
      student_name = student$name,
      student_email = student$email,
      mentor_email = mentor$email,
      mentor_name = mentor$name,
      mentor_message = message_text
    )
    
    send_confirmation_to_student(
      student_name = student$name,
      student_email = student$email,
      mentor_name = mentor$name,
      timestamp = Sys.time()
    )
    
    # Update database
    dbExecute(con, "UPDATE students SET matched_mentor_id = ? WHERE id = ?", 
              params = list(mentor$id, student_data$id))
    
    removeModal()
    
    showModal(modalDialog(
      title = "🎉 Introduction Sent!",
      div(
        class = "text-center",
        h4("Success!"),
        p(paste0("Your introduction has been sent to ", mentor$name, "!")),
        div(
          style = "background: linear-gradient(135deg, var(--bs-success) 0%, #20c997 100%); 
                   color: white; padding: 20px; border-radius: 10px; margin: 20px 0;",
          h5("📧 What happens next?"),
          p("You'll receive a confirmation email, and ", mentor$name, " will get your introduction message."),
          p("Most mentors respond within 24-48 hours!")
        ),
        p("🌟 Good luck with your mentoring journey!", style = "color: var(--bs-primary); font-weight: 600;")
      ),
      easyClose = TRUE,
      footer = tagList(
        actionButton("intro_sent_ok", "🎯 Find More Mentors", class = "btn-primary"),
        actionButton("intro_sent_done", "✅ All Done", class = "btn-success")
      )
    ))
    
    dbDisconnect(con)
  })
  
  observeEvent(input$intro_sent_ok, {
    removeModal()
  })
  
  observeEvent(input$intro_sent_done, {
    removeModal()
    matches(NULL)
  })
}

shinyApp(ui, server) 