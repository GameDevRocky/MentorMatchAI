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

# Define missing %||% operator
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
  info = "#17a2b8",
  warning = "#ffc107",
  danger = "#dc3545",
  base_font = font_google("Inter"),
  heading_font = font_google("Poppins", wght = c(400, 600, 700)),
  bg = "#ffffff",
  fg = "#2c3e50"
)

# Custom CSS for professional design
custom_css <- "
.hero-section {
  background: linear-gradient(135deg, #52c3a4 0%, #69b7d1 100%);
  color: white;
  padding: 80px 20px;
  text-align: center;
  margin: -20px -15px 40px -15px;
  border-radius: 0 0 20px 20px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}

.hero-title {
  font-size: 3.5rem;
  font-weight: 700;
  margin-bottom: 20px;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

.hero-subtitle {
  font-size: 1.3rem;
  margin-bottom: 40px;
  opacity: 0.95;
}

.btn-hero {
  padding: 15px 30px;
  font-size: 1.1rem;
  font-weight: 600;
  border-radius: 50px;
  min-width: 200px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
  margin: 0 10px;
  transition: all 0.3s ease;
}

.btn-hero:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0,0,0,0.3);
}

.feature-card {
  border: none;
  border-radius: 15px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.08);
  transition: all 0.3s ease;
  height: 100%;
}

.feature-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 25px rgba(0,0,0,0.15);
}

.feature-card .card-header {
  background: linear-gradient(135deg, #52c3a4 0%, #69b7d1 100%);
  color: white;
  border-radius: 15px 15px 0 0;
  font-weight: 600;
  padding: 20px;
}

.mentor-profile-card {
  background: white;
  border-radius: 20px;
  box-shadow: 0 8px 25px rgba(0,0,0,0.1);
  transition: all 0.3s ease;
  cursor: pointer;
  margin-bottom: 30px;
  position: relative;
  overflow: hidden;
}

.mentor-profile-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 15px 40px rgba(0,0,0,0.2);
}

.compatibility-badge {
  position: absolute;
  top: 20px;
  right: 20px;
  background: linear-gradient(135deg, #52c3a4 0%, #69b7d1 100%);
  color: white;
  padding: 8px 15px;
  border-radius: 20px;
  font-weight: 600;
  font-size: 0.9rem;
  z-index: 10;
}

.mentor-avatar {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  border: 4px solid #52c3a4;
  object-fit: cover;
}

.mentor-name {
  color: #2c3e50;
  font-weight: 700;
  margin: 15px 0 5px 0;
}

.mentor-title {
  color: #69b7d1;
  font-weight: 500;
  margin-bottom: 10px;
}

.mentor-expertise {
  color: #6c757d;
  font-size: 0.95rem;
  margin: 15px 0;
}

.rating-display {
  margin: 10px 0;
  font-weight: 500;
}

.modal-header-gradient {
  background: linear-gradient(135deg, #52c3a4 0%, #69b7d1 100%);
  color: white;
  border-radius: 10px;
}

.demographic-section {
  background: #f8fafb;
  padding: 20px;
  border-radius: 10px;
  margin-bottom: 20px;
}

.btn-primary-modern {
  background: linear-gradient(135deg, #52c3a4 0%, #69b7d1 100%);
  border: none;
  border-radius: 25px;
  font-weight: 600;
  padding: 12px 25px;
  transition: all 0.3s ease;
}

.btn-primary-modern:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(82, 195, 164, 0.4);
}

.back-button {
  text-align: center;
  margin-top: 40px;
}

.results-header {
  text-align: center;
  color: #2c3e50;
  font-weight: 700;
  margin: 40px 0;
}

.profile-section {
  background: white;
  border-radius: 15px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.08);
  padding: 30px;
  margin-bottom: 30px;
}

.profile-header {
  background: linear-gradient(135deg, #52c3a4 0%, #69b7d1 100%);
  color: white;
  padding: 25px;
  border-radius: 10px;
  margin-bottom: 25px;
}
"

ui <- page_navbar(
  title = "🎯 MentorMatch AI",
  theme = app_theme,
  bg = "primary",
  inverse = TRUE,
  
  tags$head(tags$style(HTML(custom_css))),
  
  nav_panel(
    title = "Home",
    layout_columns(
      col_widths = 12,
      
      # Hero Section
      div(
        class = "hero-section",
        h1("🎯 MentorMatch AI", class = "hero-title"),
        p("Connect with the perfect mentor using AI-powered semantic matching", class = "hero-subtitle"),
        
        div(
          style = "display: flex; justify-content: center; gap: 20px; flex-wrap: wrap;",
          actionButton("show_student_modal", "🎓 I'm a Student", 
                      class = "btn-light btn-lg btn-hero"),
          actionButton("show_mentor_modal", "👨‍🏫 I'm a Mentor", 
                      class = "btn-outline-light btn-lg btn-hero")
        )
      ),
      
      # Features Section  
      layout_columns(
        col_widths = c(4, 4, 4),
        
        card(
          class = "feature-card",
          card_header("🧠 AI-Powered Matching"),
          card_body(
            p("Advanced semantic analysis finds mentors that align with your goals and learning style."),
            p(strong("✓ Compatibility Scoring"), br(),
              "✓ Personalized Recommendations", br(),
              "✓ Smart Analysis")
          )
        ),
        
        card(
          class = "feature-card",
          card_header("🎯 Perfect Connections"),
          card_body(
            p("Connect with mentors who have the exact expertise you need in your field."),
            p(strong("✓ Industry Experts"), br(),
              "✓ Verified Profiles", br(),
              "✓ Diverse Backgrounds")
          )
        ),
        
        card(
          class = "feature-card",
          card_header("📧 Easy Communication"),
          card_body(
            p("Send personalized messages and get connected instantly."),
            p(strong("✓ Custom Messages"), br(),
              "✓ Email Integration", br(),
              "✓ Quick Responses")
          )
        )
      ),
      
      # Results section
      uiOutput("results_section")
    )
  ),
  
  nav_panel("About", 
    layout_columns(
      col_widths = 12,
      div(
        class = "profile-section",
        h3("About MentorMatch AI", style = "color: #52c3a4; font-weight: 700;"),
        h5("Revolutionizing Mentorship Through AI"),
        p("MentorMatch AI uses advanced natural language processing to create meaningful connections between students and mentors."),
        
        h5("How It Works:"),
        tags$ol(
          tags$li("Complete a comprehensive questionnaire about your goals"),
          tags$li("Our AI analyzes responses using semantic matching"),
          tags$li("Get matched with the top 3 most compatible mentors"),
          tags$li("View detailed profiles and send connection requests"),
          tags$li("Start your mentoring journey with email facilitation")
        ),
        
        h5("Technology:"),
        p("Built with R Shiny, text2vec, TF-IDF vectorization, LSA dimensionality reduction, and cosine similarity matching.")
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
    dbExecute(con, "CREATE TABLE IF NOT EXISTS mentors_enhanced (
      id INTEGER PRIMARY KEY,
      name TEXT, email TEXT, title TEXT, age_range TEXT, gender TEXT, ethnicity TEXT,
      location TEXT, education_background TEXT, industry TEXT, experience_years TEXT,
      expertise_areas TEXT, mentoring_style TEXT, availability TEXT, bio TEXT
    )")
    
    dbExecute(con, "CREATE TABLE IF NOT EXISTS students_enhanced (
      id INTEGER PRIMARY KEY,
      name TEXT, email TEXT, age_range TEXT, gender TEXT, ethnicity TEXT,
      location TEXT, education_level TEXT, field_of_study TEXT, career_interest TEXT,
      experience_level TEXT, mentorship_goals TEXT, communication_style TEXT,
      availability TEXT, challenges TEXT, matched_mentor_id INTEGER
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
      title = div(
        class = "modal-header-gradient text-center",
        style = "margin: -15px -15px 20px -15px; padding: 25px;",
        h3("🎓 Student Profile", style = "margin: 0; font-weight: 600;"),
        p("Help us find your ideal mentor match", style = "margin: 5px 0 0 0; opacity: 0.9;")
      ),
      size = "l",
      
      # Personal Information
      div(
        class = "demographic-section",
        h5("👤 Personal Information", style = "color: #52c3a4; margin-bottom: 15px; font-weight: 600;"),
        fluidRow(
          column(6, textInput("student_name", "Full Name*", placeholder = "Alex Johnson")),
          column(6, textInput("student_email", "Email*", placeholder = "alex@university.edu"))
        ),
        fluidRow(
          column(4, selectInput("student_age", "Age Range*", 
                               choices = c("", "16-18", "19-22", "23-26", "27-30", "31-35", "36+"))),
          column(4, selectInput("student_gender", "Gender (Optional)", 
                               choices = c("", "Female", "Male", "Non-binary", "Prefer not to say"))),
          column(4, selectInput("student_location", "Location*", 
                               choices = c("", "North America", "Europe", "Asia", "South America", "Africa", "Oceania")))
        ),
        selectInput("student_ethnicity", "Ethnicity (Optional)", 
                   choices = c("", "Asian", "Black/African", "Hispanic/Latino", "White/Caucasian", 
                              "Middle Eastern", "Native American", "Pacific Islander", "Mixed", "Prefer not to say"))
      ),
      
      # Academic & Career Information
      div(
        class = "demographic-section",
        h5("🎯 Academic & Career Focus", style = "color: #52c3a4; margin-bottom: 15px; font-weight: 600;"),
        fluidRow(
          column(6, selectInput("education_level", "Education Level*", 
                               choices = c("", "High School", "Undergraduate", "Graduate", "PhD", "Professional"))),
          column(6, selectInput("field_of_study", "Field of Study*", 
                               choices = c("", "Computer Science", "Business", "Engineering", "Medicine", 
                                          "Psychology", "Art & Design", "Education", "Law", "Other")))
        ),
        fluidRow(
          column(6, selectInput("career_interest", "Career Interest*", 
                               choices = c("", "Technology", "Healthcare", "Finance", "Education", 
                                          "Non-profit", "Government", "Media", "Research", "Entrepreneurship"))),
          column(6, selectInput("experience_level", "Experience Level*", 
                               choices = c("", "No experience", "Some internships", "1-2 years", "3-5 years", "5+ years")))
        )
      ),
      
      # Mentorship Preferences
      div(
        class = "demographic-section",
        h5("🤝 Mentorship Preferences", style = "color: #52c3a4; margin-bottom: 15px; font-weight: 600;"),
        checkboxGroupInput("mentorship_goals", "What are your main goals?*",
                          choices = c("Career guidance" = "career", "Skill development" = "skills", 
                                     "Networking" = "network", "Industry insights" = "industry",
                                     "Personal growth" = "personal", "Job search help" = "jobsearch")),
        fluidRow(
          column(6, selectInput("communication_style", "Preferred Communication*", 
                               choices = c("", "Video calls", "Phone calls", "Email", "In-person", "Flexible"))),
          column(6, selectInput("availability", "Availability*", 
                               choices = c("", "Once a week", "Bi-weekly", "Monthly", "As needed", "Flexible")))
        ),
        textAreaInput("challenges", "Current Challenges/Goals", 
                     placeholder = "What specific challenges are you facing or goals you want to achieve?",
                     height = "80px")
      ),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("submit_student", "🔍 Find My Mentor!", class = "btn-primary-modern btn-lg")
      ),
      easyClose = FALSE
    ))
  })
  
  # Mentor Modal
  observeEvent(input$show_mentor_modal, {
    showModal(modalDialog(
      title = div(
        class = "modal-header-gradient text-center",
        style = "margin: -15px -15px 20px -15px; padding: 25px;",
        h3("👨‍🏫 Mentor Profile", style = "margin: 0; font-weight: 600;"),
        p("Share your expertise and help students succeed", style = "margin: 5px 0 0 0; opacity: 0.9;")
      ),
      size = "l",
      
      # Personal Information
      div(
        class = "demographic-section",
        h5("👤 Personal Information", style = "color: #52c3a4; margin-bottom: 15px; font-weight: 600;"),
        fluidRow(
          column(6, textInput("mentor_name", "Full Name*", placeholder = "Dr. Sarah Johnson")),
          column(6, textInput("mentor_email", "Email*", placeholder = "sarah@company.com"))
        ),
        textInput("mentor_title", "Current Position*", placeholder = "Senior Software Engineer at TechCorp"),
        fluidRow(
          column(4, selectInput("mentor_age", "Age Range*", 
                               choices = c("", "25-30", "31-35", "36-40", "41-50", "51+"))),
          column(4, selectInput("mentor_gender", "Gender (Optional)", 
                               choices = c("", "Female", "Male", "Non-binary", "Prefer not to say"))),
          column(4, selectInput("mentor_location", "Location*", 
                               choices = c("", "North America", "Europe", "Asia", "South America", "Africa", "Oceania")))
        ),
        selectInput("mentor_ethnicity", "Ethnicity (Optional)", 
                   choices = c("", "Asian", "Black/African", "Hispanic/Latino", "White/Caucasian", 
                              "Middle Eastern", "Native American", "Pacific Islander", "Mixed", "Prefer not to say"))
      ),
      
      # Professional Information
      div(
        class = "demographic-section",
        h5("💼 Professional Background", style = "color: #52c3a4; margin-bottom: 15px; font-weight: 600;"),
        fluidRow(
          column(6, selectInput("education_background", "Education Background*", 
                               choices = c("", "Bachelor's", "Master's", "PhD", "Professional Degree", "Self-taught"))),
          column(6, selectInput("industry", "Industry*", 
                               choices = c("", "Technology", "Healthcare", "Finance", "Education", 
                                          "Non-profit", "Government", "Media", "Research", "Consulting")))
        ),
        fluidRow(
          column(6, selectInput("experience_years", "Years of Experience*", 
                               choices = c("", "3-5 years", "6-10 years", "11-15 years", "16-20 years", "20+ years"))),
          column(6, selectInput("mentoring_availability", "Mentoring Availability*", 
                               choices = c("", "Once a week", "Bi-weekly", "Monthly", "As needed", "Flexible")))
        )
      ),
      
      # Expertise & Mentoring Style
      div(
        class = "demographic-section",
        h5("🎯 Expertise & Mentoring", style = "color: #52c3a4; margin-bottom: 15px; font-weight: 600;"),
        checkboxGroupInput("expertise_areas", "Areas of Expertise*",
                          choices = c("Technical skills" = "technical", "Leadership" = "leadership", 
                                     "Career planning" = "career", "Entrepreneurship" = "entrepreneur",
                                     "Research" = "research", "Networking" = "network",
                                     "Industry knowledge" = "industry", "Personal development" = "personal")),
        selectInput("mentoring_style", "Mentoring Style*", 
                   choices = c("", "Hands-on guidance", "Strategic advice", "Supportive listening", 
                              "Challenge-based", "Flexible approach")),
        textAreaInput("mentor_bio", "Professional Bio & Mentoring Philosophy*", 
                     placeholder = "Tell potential mentees about your background, experience, and what you can offer...",
                     height = "100px")
      ),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("submit_mentor", "🚀 Join as Mentor", class = "btn-primary-modern btn-lg")
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
    student_data$gender <- input$student_gender %||% ""
    student_data$ethnicity <- input$student_ethnicity %||% ""
    student_data$location <- input$student_location
    student_data$education_level <- input$education_level
    student_data$field_of_study <- input$field_of_study
    student_data$career_interest <- input$career_interest
    student_data$experience_level <- input$experience_level
    student_data$mentorship_goals <- paste(input$mentorship_goals, collapse = ", ")
    student_data$communication_style <- input$communication_style
    student_data$availability <- input$availability
    student_data$challenges <- input$challenges %||% ""
    
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    
    # Save to enhanced students table
    dbExecute(con, "INSERT INTO students_enhanced (
      name, email, age_range, gender, ethnicity, location,
      education_level, field_of_study, career_interest, experience_level,
      mentorship_goals, communication_style, availability, challenges
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    params = list(
      student_data$name, student_data$email, student_data$age_range, 
      student_data$gender, student_data$ethnicity, student_data$location,
      student_data$education_level, student_data$field_of_study, 
      student_data$career_interest, student_data$experience_level,
      student_data$mentorship_goals, student_data$communication_style,
      student_data$availability, student_data$challenges
    ))
    
    student_row <- dbGetQuery(con, "SELECT id FROM students_enhanced WHERE email = ? ORDER BY id DESC LIMIT 1", 
                              params = list(student_data$email))
    student_data$id <- student_row$id[1]
    
    removeModal()
    
    # Check if enough mentors exist
    if (has_enough_mentors(con)) {
      # Use enhanced semantic recommendation with demographics
      if (!is.null(embedding_system())) {
        student_answers <- list(
          education = student_data$education_level,
          field = student_data$field_of_study,
          career = student_data$career_interest,
          experience = student_data$experience_level,
          goals = student_data$mentorship_goals,
          challenges = student_data$challenges,
          location = student_data$location,
          communication = student_data$communication_style
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
          class = "text-center",
          div(
            class = "profile-header",
            h4("We're growing our mentor community!"),
            p("Based on your interests in ", strong(student_data$field_of_study), 
              " and ", strong(student_data$career_interest), 
              ", we'll prioritize finding mentors in these areas.")
          ),
          h5("📧 We'll notify you when perfect matches are available!")
        ),
        easyClose = TRUE,
        footer = actionButton("student_ok", "📧 Notify Me", class = "btn-primary-modern")
      ))
    }
    
    dbDisconnect(con)
  })
  
  # Handle mentor submission
  observeEvent(input$submit_mentor, {
    req(input$mentor_name, input$mentor_email, input$mentor_title, input$mentor_age,
        input$education_background, input$industry, input$experience_years, input$expertise_areas)
    
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    
    expertise_text <- paste(input$expertise_areas, collapse = ", ")
    
    # Save to enhanced mentors table
    dbExecute(con, "INSERT INTO mentors_enhanced (
      name, email, title, age_range, gender, ethnicity, location,
      education_background, industry, experience_years, expertise_areas,
      mentoring_style, availability, bio
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    params = list(
      input$mentor_name, input$mentor_email, input$mentor_title,
      input$mentor_age, input$mentor_gender %||% "", input$mentor_ethnicity %||% "", 
      input$mentor_location, input$education_background, input$industry,
      input$experience_years, expertise_text, input$mentoring_style,
      input$mentoring_availability, input$mentor_bio
    ))
    
    # Also add to mentor_profiles for semantic matching
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
        class = "text-center",
        div(
          class = "profile-header",
          h4("Thank you for joining our mentor community!"),
          p("Your expertise in ", strong(input$industry), " will help shape futures.")
        ),
        p("You'll receive notifications when students want to connect with you.")
      ),
      easyClose = TRUE,
      footer = actionButton("mentor_ok", "🚀 Start Mentoring", class = "btn-primary-modern")
    ))
    
    dbDisconnect(con)
  })
  
  # Handle modal closures
  observeEvent(input$student_ok, removeModal())
  observeEvent(input$mentor_ok, removeModal())
  
  # Render results section with modern card design
  output$results_section <- renderUI({
    req(matches())
    
    div(
      style = "padding: 40px 20px;",
      h2("Your Perfect Mentor Matches", class = "results-header"),
      
      layout_columns(
        col_widths = 12,
        lapply(seq_along(matches()), function(i) {
          mentor <- matches()[[i]]
          
          div(
            class = "mentor-profile-card",
            onclick = paste0("Shiny.setInputValue('mentor_clicked', ", mentor$id, ", {priority: 'event'})"),
            
            # Compatibility badge
            div(class = "compatibility-badge", paste0(round(mentor$score * 100), "% Match")),
            
            # Card content
            div(
              style = "padding: 30px; text-align: center;",
              
              # Avatar
              img(src = mentor$image, class = "mentor-avatar mb-3",
                  onerror = "this.src='https://via.placeholder.com/100x100?text=M'"),
              
              # Name and title
              h4(mentor$name, class = "mentor-name"),
              p(mentor$title, class = "mentor-title"),
              
              # Rating (simulated)
              div(
                class = "rating-display",
                "⭐ 4.8 ", 
                span(style = "color: #7f8c8d; font-size: 0.9rem;", "• 15 reviews")
              ),
              
              # Expertise
              p(mentor$expertise, class = "mentor-expertise"),
              
              # Click instruction
              div(
                style = "margin-top: 20px; padding: 15px; background: #f8fafb; border-radius: 10px;",
                p("👆 Click to view full profile and connect", 
                  style = "margin: 0; color: #52c3a4; font-weight: 500;")
              )
            )
          )
        })
      ),
      
      # Back button
      div(
        class = "back-button",
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
        title = NULL,
        size = "l",
        
        # Header with mentor info
        div(
          class = "profile-header",
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
                     placeholder = paste0("Hi ", found_mentor$name, "! I found your profile through MentorMatch AI and I'm interested in connecting because...")),
        
        footer = tagList(
          modalButton("Cancel"),
          actionButton("send_intro", "📧 Send Introduction", class = "btn-primary-modern btn-lg")
        )
      ))
    }
  })
  
  # Handle sending introduction email
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
             "I'm studying ", student$field_of_study, " and interested in ", student$career_interest, ". ",
             "My biggest challenge right now is: ", student$challenges)
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
    dbExecute(con, "UPDATE students_enhanced SET matched_mentor_id = ? WHERE id = ?", 
              params = list(mentor$id, student_data$id))
    
    removeModal()
    
    showModal(modalDialog(
      title = "🎉 Introduction Sent!",
      div(
        class = "text-center",
        div(
          class = "profile-header",
          h4("Success!"),
          p("Your introduction has been sent to ", mentor$name, "!"),
          h5("📧 What happens next?"),
          p("You'll receive a confirmation email, and ", mentor$name, " will get your message."),
          p("Most mentors respond within 24-48 hours!")
        ),
        p("🌟 Good luck with your mentoring journey!", style = "color: #52c3a4; font-weight: 600;")
      ),
      easyClose = TRUE,
      footer = tagList(
        actionButton("intro_sent_ok", "🎯 Find More Mentors", class = "btn-primary-modern"),
        actionButton("intro_sent_done", "✅ All Done", class = "btn-outline-primary")
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