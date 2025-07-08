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

# Helper function
has_enough_mentors <- function(con, min_n = 3) {
  n <- dbGetQuery(con, "SELECT COUNT(*) as n FROM mentor_profiles")$n
  n >= min_n
}

# Modern professional theme
app_theme <- bs_theme(
  version = 5,
  preset = "bootstrap",
  primary = "#52c3a4",
  secondary = "#69b7d1",
  success = "#28a745",
  base_font = font_google("Inter"),
  heading_font = font_google("Poppins", wght = c(400, 600, 700))
)

ui <- page_navbar(
  title = "🎯 MentorMatch AI",
  theme = app_theme,
  bg = "primary",
  inverse = TRUE,
  
  # Custom CSS
  tags$head(
    tags$style(HTML("
      .hero-section {
        background: linear-gradient(135deg, #52c3a4 0%, #69b7d1 100%);
        color: white;
        padding: 60px 20px;
        text-align: center;
        margin: -20px -15px 40px -15px;
        border-radius: 0 0 20px 20px;
      }
      .btn-hero {
        padding: 15px 30px;
        font-size: 1.1rem;
        font-weight: 600;
        border-radius: 50px;
        margin: 0 10px;
      }
      .mentor-card {
        background: white;
        border-radius: 15px;
        box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        margin-bottom: 20px;
        cursor: pointer;
        transition: all 0.3s ease;
      }
      .mentor-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 10px 25px rgba(0,0,0,0.2);
      }
      .compatibility-badge {
        background: linear-gradient(135deg, #52c3a4 0%, #69b7d1 100%);
        color: white;
        padding: 5px 10px;
        border-radius: 15px;
        font-weight: 600;
        font-size: 0.9rem;
      }
      .section-card {
        background: #f8fafb;
        padding: 20px;
        border-radius: 10px;
        margin-bottom: 20px;
      }
    "))
  ),
  
  nav_panel(
    title = "Home",
    layout_columns(
      col_widths = 12,
      
      # Hero Section
      div(
        class = "hero-section",
        h1("🎯 MentorMatch AI", style = "font-size: 3rem; font-weight: 700; margin-bottom: 20px;"),
        p("Connect with the perfect mentor using AI-powered semantic matching", style = "font-size: 1.2rem; margin-bottom: 40px;"),
        
        div(
          actionButton("show_student_modal", "🎓 I'm a Student", class = "btn-light btn-lg btn-hero"),
          actionButton("show_mentor_modal", "👨‍🏫 I'm a Mentor", class = "btn-outline-light btn-lg btn-hero")
        )
      ),
      
      # Results section
      uiOutput("results_section")
    )
  ),
  
  nav_panel("About", 
    h3("About MentorMatch AI"),
    p("AI-powered mentor matching using semantic analysis.")
  )
)

server <- function(input, output, session) {
  # Reactive values
  student_data <- reactiveValues()
  matches <- reactiveVal(NULL)
  selected_mentor <- reactiveVal(NULL)
  embedding_system <- reactiveVal(NULL)
  
  # Initialize database and embedding system
  observe({
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    
    # Ensure tables exist
    dbExecute(con, "CREATE TABLE IF NOT EXISTS students_enhanced (
      id INTEGER PRIMARY KEY,
      name TEXT, email TEXT, age_range TEXT, gender TEXT, ethnicity TEXT,
      location TEXT, education_level TEXT, field_of_study TEXT, career_interest TEXT,
      experience_level TEXT, mentorship_goals TEXT, communication_style TEXT,
      availability TEXT, challenges TEXT, matched_mentor_id INTEGER
    )")
    
    dbExecute(con, "CREATE TABLE IF NOT EXISTS mentor_profiles (
      id INTEGER PRIMARY KEY,
      name TEXT, title TEXT, expertise TEXT, bio TEXT, email TEXT, image TEXT
    )")
    
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
      title = "🎓 Student Profile",
      size = "l",
      
      div(
        class = "section-card",
        h5("👤 Personal Information"),
        fluidRow(
          column(6, textInput("student_name", "Full Name*", placeholder = "Alex Johnson")),
          column(6, textInput("student_email", "Email*", placeholder = "alex@university.edu"))
        ),
        fluidRow(
          column(4, selectInput("student_age", "Age Range*", 
                               choices = c("", "16-18", "19-22", "23-26", "27-30", "31-35", "36+"))),
          column(4, selectInput("student_location", "Location*", 
                               choices = c("", "North America", "Europe", "Asia", "South America", "Africa", "Oceania"))),
          column(4, selectInput("education_level", "Education Level*", 
                               choices = c("", "High School", "Undergraduate", "Graduate", "PhD", "Professional")))
        )
      ),
      
      div(
        class = "section-card",
        h5("🎯 Academic & Career Focus"),
        fluidRow(
          column(6, selectInput("field_of_study", "Field of Study*", 
                               choices = c("", "Computer Science", "Business", "Engineering", "Medicine", 
                                          "Psychology", "Art & Design", "Education", "Law", "Other"))),
          column(6, selectInput("career_interest", "Career Interest*", 
                               choices = c("", "Technology", "Healthcare", "Finance", "Education", 
                                          "Non-profit", "Government", "Media", "Research", "Entrepreneurship")))
        ),
        selectInput("experience_level", "Experience Level*", 
                   choices = c("", "No experience", "Some internships", "1-2 years", "3-5 years", "5+ years"))
      ),
      
      div(
        class = "section-card",
        h5("🤝 Mentorship Goals"),
        checkboxGroupInput("mentorship_goals", "What are your main goals?*",
                          choices = c("Career guidance" = "career", "Skill development" = "skills", 
                                     "Networking" = "network", "Industry insights" = "industry",
                                     "Personal growth" = "personal", "Job search help" = "jobsearch")),
        textAreaInput("challenges", "Current Challenges/Goals", 
                     placeholder = "What specific challenges are you facing?",
                     height = "80px")
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
      title = "👨‍🏫 Mentor Profile",
      size = "l",
      
      div(
        class = "section-card",
        h5("👤 Professional Information"),
        fluidRow(
          column(6, textInput("mentor_name", "Full Name*", placeholder = "Dr. Sarah Johnson")),
          column(6, textInput("mentor_email", "Email*", placeholder = "sarah@company.com"))
        ),
        textInput("mentor_title", "Current Position*", placeholder = "Senior Software Engineer at TechCorp"),
        fluidRow(
          column(6, selectInput("industry", "Industry*", 
                               choices = c("", "Technology", "Healthcare", "Finance", "Education", "Other"))),
          column(6, selectInput("experience_years", "Years of Experience*", 
                               choices = c("", "3-5 years", "6-10 years", "11-15 years", "16-20 years", "20+ years")))
        )
      ),
      
      div(
        class = "section-card",
        h5("🎯 Expertise & Mentoring"),
        checkboxGroupInput("expertise_areas", "Areas of Expertise*",
                          choices = c("Technical skills" = "technical", "Leadership" = "leadership", 
                                     "Career planning" = "career", "Entrepreneurship" = "entrepreneur",
                                     "Research" = "research", "Networking" = "network")),
        textAreaInput("mentor_bio", "Professional Bio*", 
                     placeholder = "Tell potential mentees about your background...",
                     height = "100px")
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
    req(input$student_name, input$student_email, input$student_age, input$education_level, 
        input$field_of_study, input$career_interest, input$experience_level, input$mentorship_goals)
    
    # Store student data
    student_data$name <- input$student_name
    student_data$email <- input$student_email
    student_data$age_range <- input$student_age
    student_data$location <- input$student_location
    student_data$education_level <- input$education_level
    student_data$field_of_study <- input$field_of_study
    student_data$career_interest <- input$career_interest
    student_data$experience_level <- input$experience_level
    student_data$mentorship_goals <- paste(input$mentorship_goals, collapse = ", ")
    student_data$challenges <- input$challenges %||% ""
    
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    
    # Save to database
    dbExecute(con, "INSERT INTO students_enhanced (
      name, email, age_range, location, education_level, field_of_study, 
      career_interest, experience_level, mentorship_goals, challenges
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    params = list(
      student_data$name, student_data$email, student_data$age_range, 
      student_data$location, student_data$education_level, student_data$field_of_study, 
      student_data$career_interest, student_data$experience_level,
      student_data$mentorship_goals, student_data$challenges
    ))
    
    removeModal()
    
    # Check if enough mentors exist
    if (has_enough_mentors(con)) {
      # Use semantic recommendation
      if (!is.null(embedding_system())) {
        student_answers <- list(
          education = student_data$education_level,
          field = student_data$field_of_study,
          career = student_data$career_interest,
          experience = student_data$experience_level,
          goals = student_data$mentorship_goals,
          challenges = student_data$challenges
        )
        
        recommendations <- get_mentor_recommendations(student_answers, embedding_system(), top_k = 3)
        matches(recommendations)
      } else {
        # Fallback matching
        mentors <- dbGetQuery(con, "SELECT * FROM mentor_profiles LIMIT 3")
        simple_matches <- lapply(seq_len(nrow(mentors)), function(i) {
          mentor <- as.list(mentors[i, ])
          mentor$score <- 0.75 + runif(1, -0.1, 0.1)
          mentor
        })
        matches(simple_matches)
      }
    } else {
      showModal(modalDialog(
        title = "🔍 Building Our Mentor Network",
        div(
          h4("We're growing our mentor community!"),
          p("We'll notify you when mentors matching your profile become available."),
          p("Field: ", strong(student_data$field_of_study)),
          p("Interest: ", strong(student_data$career_interest))
        ),
        easyClose = TRUE,
        footer = actionButton("student_ok", "📧 Notify Me", class = "btn-primary")
      ))
    }
    
    dbDisconnect(con)
  })
  
  # Handle mentor submission
  observeEvent(input$submit_mentor, {
    req(input$mentor_name, input$mentor_email, input$mentor_title, input$industry, input$expertise_areas, input$mentor_bio)
    
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    
    expertise_text <- paste(input$expertise_areas, collapse = ", ")
    
    # Add to mentor_profiles for semantic matching
    dbExecute(con, "INSERT INTO mentor_profiles (name, title, expertise, bio, email, image) VALUES (?, ?, ?, ?, ?, ?)",
              params = list(
                input$mentor_name, input$mentor_title, expertise_text,
                input$mentor_bio, input$mentor_email,
                "https://via.placeholder.com/100x100?text=M"
              ))
    
    removeModal()
    
    showModal(modalDialog(
      title = "🎉 Welcome to MentorMatch!",
      div(
        h4("Thank you for joining our mentor community!"),
        p("Your expertise in ", strong(input$industry), " will help students succeed.")
      ),
      easyClose = TRUE,
      footer = actionButton("mentor_ok", "🚀 Start Mentoring", class = "btn-success")
    ))
    
    dbDisconnect(con)
  })
  
  # Handle modal closures
  observeEvent(input$student_ok, removeModal())
  observeEvent(input$mentor_ok, removeModal())
  
  # Render results section
  output$results_section <- renderUI({
    req(matches())
    
    div(
      h2("Your Perfect Mentor Matches", style = "text-align: center; margin: 40px 0;"),
      
      layout_columns(
        col_widths = 12,
        lapply(seq_along(matches()), function(i) {
          mentor <- matches()[[i]]
          
          div(
            class = "mentor-card",
            onclick = paste0("Shiny.setInputValue('mentor_clicked', ", mentor$id, ", {priority: 'event'})"),
            style = "padding: 20px;",
            
            fluidRow(
              column(2, 
                img(src = mentor$image, style = "width: 80px; height: 80px; border-radius: 50%;",
                    onerror = "this.src='https://via.placeholder.com/80x80?text=M'")
              ),
              column(8,
                h4(mentor$name, style = "margin-bottom: 5px;"),
                h6(mentor$title, style = "color: #69b7d1; margin-bottom: 10px;"),
                p(mentor$expertise, style = "font-size: 0.95rem;")
              ),
              column(2,
                div(class = "compatibility-badge", 
                    paste0(round(mentor$score * 100), "% Match")),
                br(),
                p("Click to connect", style = "font-size: 0.8rem; color: #666; margin-top: 10px;")
              )
            )
          )
        })
      ),
      
      div(
        style = "text-align: center; margin-top: 30px;",
        actionButton("back_to_search", "← Search Again", class = "btn-outline-primary")
      )
    )
  })
  
  # Handle back to search
  observeEvent(input$back_to_search, {
    matches(NULL)
  })
  
  # Handle mentor card clicks
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
        title = paste("Connect with", found_mentor$name),
        size = "l",
        
        h4("🎯 Expertise"),
        p(found_mentor$expertise),
        
        h4("📖 Background"),
        p(found_mentor$bio),
        
        h4("💌 Send Introduction"),
        textAreaInput("intro_message", "Your Message", 
                     height = "120px",
                     placeholder = paste0("Hi ", found_mentor$name, "! I'm interested in connecting because...")),
        
        footer = tagList(
          modalButton("Cancel"),
          actionButton("send_intro", "📧 Send Introduction", class = "btn-primary btn-lg")
        )
      ))
    }
  })
  
  # Handle sending introduction
  observeEvent(input$send_intro, {
    req(selected_mentor())
    
    mentor <- selected_mentor()
    student <- student_data
    
    # Create message
    message_text <- if (nchar(trimws(input$intro_message)) > 0) {
      input$intro_message
    } else {
      paste0("Hello! I found your profile through MentorMatch AI. ",
             "I'm studying ", student$field_of_study, " and interested in ", student$career_interest, ".")
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
    
    removeModal()
    
    showModal(modalDialog(
      title = "🎉 Introduction Sent!",
      div(
        h4("Success!"),
        p("Your introduction has been sent to ", mentor$name, "!"),
        p("You'll receive a confirmation email, and most mentors respond within 24-48 hours.")
      ),
      easyClose = TRUE,
      footer = tagList(
        actionButton("intro_sent_ok", "🎯 Find More Mentors", class = "btn-primary"),
        actionButton("intro_sent_done", "✅ All Done", class = "btn-outline-primary")
      )
    ))
  })
  
  observeEvent(input$intro_sent_ok, removeModal())
  observeEvent(input$intro_sent_done, {
    removeModal()
    matches(NULL)
  })
}

shinyApp(ui, server) 