library(shiny)
library(bslib)
library(RSQLite)
library(DBI)
source("database_setup.R")
source("mentor_recommender.R")
source("email_utils.R")

student_questionaire_ui <- function(id) {
  ns <- NS(id)
  page_fluid(
  theme = bs_theme(version = 5, bootswatch = "minty"),
    tags$head(tags$style("
  .questionaire_modal_title {
  text-align: center;
  }
                        
    .profile-preview {
      max-width: 200px;
      max-height: 200px;
      margin: 10px 0;
      border-radius: 50%;
      object-fit: cover;
    }
    ")),
  
  # Main page content
  div(
    class = "d-flex justify-content-center align-items-center vh-100",
    div(
      class = "text-center",
      h1("MentorMatch.io", class = "mb-4"),
      p("Your AI assisted mentor finder
        Connect with mentors who can guide your academic and career journey", 
        class = "lead mb-4"),
        actionButton(ns("open_questionnaire"), "Start Questionnaire", class = "btn-primary btn-lg", icon = icon("clipboard-list"))
    )
  )
)
}

student_questionaire_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    # Create reactive values to store form responses
    form_data <- reactiveValues(
      name = NULL,
      email = NULL,
      school_name = NULL,
      profile_picture = NULL,
      fields = NULL,
      environment = NULL,
      guidance = NULL,
      mentorship_type = NULL,
      feedback_style = NULL,
      comm_style = NULL,
      frequency = NULL,
      values = NULL,
      challenges = NULL,
      outcomes = NULL,
      additional = NULL
    )
    
    # Create a reactive value for the preview image
    preview_image <- reactiveVal(NULL)
    
    # Add a reactive value to store mentor recommendations
    mentor_matches <- reactiveVal(NULL)
    selected_mentor <- reactiveVal(NULL)
  
  # Show modal when button is clicked
    observeEvent(input$ns("open_questionnaire"), {
    showModal(
      modalDialog(
        title = div(id = "questionaire_modal_title",
                    "MentorMatch.io"),
        size = "l",  # Large modal
        easyClose = FALSE,  # Prevent closing by clicking outside
        
        # Questionnaire content
        div(
          style = "max-height: 70vh; overflow-y: auto; padding: 15px;",
          
          p("Please complete this questionnaire to help us match you with the right mentor.", 
            class = "lead mb-4"),
          
          #About You
          h4("About You"),
            textAreaInput(ns("name"),
                        label = "1.  Full Name", 
                        placeholder = "Adam Smith"
                        ),
            textAreaInput(ns("email"),
                        label = "2.  Email", 
                        placeholder = "asmith@gmail.com"
          ),
            textAreaInput(ns("school_name"),
                        label = "3. School Name", 
                        placeholder = "NHCS"
            ),
            
            # Profile Picture Upload
            div(
              class = "form-group",
              tags$label("4. Profile Picture"),
              fileInput(ns("profile_picture"),
                        label = NULL,
                        accept = c('image/png', 'image/jpeg', 'image/jpg'),
                        buttonLabel = "Choose Photo",
                        placeholder = "No file selected"
              ),
              uiOutput(ns("profile_preview"))
          ),
          
          # Career & Academic Preferences
          h4("Career & Academic Preferences", class = "mt-4 mb-3 text-primary"),
            textAreaInput(ns("fields"), 
            "1. What fields, subjects, or industries excite you most?",
            placeholder = "e.g., technology, healthcare, arts, business, social impact",
            height = "80px", 
            width = "100%"
          ),
            selectInput(ns("environment"),
            "2. What type of work environment appeals to you?",
            choices = c(
              "Corporate" = "corporate",
              "Startup" = "startup",
              "Non-profit" = "nonprofit",
              "Remote" = "remote",
              "Hands-on" = "handson",
              "Research-based" = "research"
            ),
            multiple = TRUE
          ),
            checkboxGroupInput(ns("guidance"),
            "3. Are you seeking guidance on:",
            choices = c(
              "College applications" = "college_apps",
              "Career exploration" = "career",
              "Skill development" = "skills",
              "Life decisions" = "life"
            )
          ),
          
          hr(),
          
          # Mentorship Style
          h4("Mentorship Style", class = "mt-4 mb-3 text-primary"),
            radioButtons(ns("mentorship_type"),
            "4. What type of mentorship relationship do you prefer?",
            choices = c(
              "Structured weekly calls" = "structured",
              "Casual check-ins" = "casual",
              "Project-based guidance" = "project",
              "Peer-like friendship" = "peer"
            )
          ),
            radioButtons(ns("feedback_style"),
            "5. How do you best receive feedback and advice?",
            choices = c(
              "Direct and honest" = "direct",
              "Encouraging and supportive" = "encouraging",
              "Detailed explanations" = "detailed",
              "Quick actionable tips" = "quick"
            )
          ),
          
          hr(),
          
          # Communication Preferences
          h4("Communication Preferences", class = "mt-4 mb-3 text-primary"),
            checkboxGroupInput(ns("comm_style"),
            "6. What communication style works best for you?",
            choices = c(
              "Video calls" = "video",
              "Text/messaging" = "text",
              "In-person meetings" = "inperson",
              "Email exchanges" = "email"
            )
          ),
            radioButtons(ns("frequency"),
            "7. How often would you like to connect with a mentor?",
            choices = c(
              "Weekly" = "weekly",
              "Bi-weekly" = "biweekly",
              "Monthly" = "monthly",
              "As-needed basis" = "asneeded"
            )
          ),
          
          hr(),
          
          # Values & Background
          h4("Values & Background", class = "mt-4 mb-3 text-primary"),
            selectInput(ns("values"),
            "8. What personal values or causes matter most to you?",
            choices = c(
              "Social justice" = "social_justice",
              "Innovation" = "innovation",
              "Community service" = "community",
              "Entrepreneurship" = "entrepreneurship",
              "Work-life balance" = "worklife",
              "Education equality" = "education",
              "Environmental sustainability" = "environment",
              "Health & wellness" = "health"
            ),
            multiple = TRUE
          ),
            textAreaInput(ns("challenges"),
            "9. What challenges or experiences have shaped your perspective?",
            placeholder = "e.g., first-generation college, financial constraints, family expectations",
            height = "80px",
            width = "100%"
          ),
          
          hr(),
          
          # Goals & Timeline
          h4("Goals & Timeline", class = "mt-4 mb-3 text-primary"),
            checkboxGroupInput(ns("outcomes"),
            "10. What specific outcomes are you hoping for from mentorship?",
            choices = c(
              "College admission success" = "college_admission",
              "Career clarity" = "career_clarity",
              "Skill building" = "skills",
              "Confidence" = "confidence",
              "Network building" = "network"
            )
          ),
            textAreaInput(ns("additional"),
            "Additional information you'd like to share:",
            height = "80px",
            width = "100%"
          )
        ),
        
        footer = div(
          modalButton("Cancel"),
            actionButton(ns("submit"), "Submit", class = "btn-primary")
        )
      )
    )
    })
    
    # Profile picture preview
    output$profile_preview <- renderUI({
      req(input$ns("profile_picture"))
      
      # Create a base64 string from the uploaded file
      file_content <- readBin(input$ns("profile_picture")$datapath, "raw", file.info(input$ns("profile_picture")$datapath)$size)
      mime_type <- switch(tools::file_ext(input$ns("profile_picture")$name),
                          "png" = "image/png",
                          "jpg" = "image/jpeg",
                          "jpeg" = "image/jpeg",
                          "gif" = "image/gif",
                          "image/png")  # default to png if unknown
      
      base64_img <- base64enc::base64encode(file_content)
      img_src <- paste0("data:", mime_type, ";base64,", base64_img)
      
      # Store the preview for later use
      preview_image(img_src)
      
      # Return the image tag
      tags$img(src = img_src,
               class = "profile-preview",
               alt = "Profile picture preview")
    })
    
    # Observe all input changes and update reactive values
    observe({
      form_data$name <- input$name
      form_data$email <- input$email
      form_data$school_name <- input$school_name
      form_data$profile_picture <- input$profile_picture
      form_data$fields <- input$fields
      form_data$environment <- input$environment
      form_data$guidance <- input$guidance
      form_data$mentorship_type <- input$mentorship_type
      form_data$feedback_style <- input$feedback_style
      form_data$comm_style <- input$comm_style
      form_data$frequency <- input$frequency
      form_data$values <- input$values
      form_data$challenges <- input$challenges
      form_data$outcomes <- input$outcomes
      form_data$additional <- input$additional
  })
  
  # Handle submission
    observeEvent(input$ns("submit"), {
      # Validate required fields
      req(form_data$name, form_data$email, form_data$school_name)
      
      # Initialize database connection
      con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
      
      # Helper function to safely convert vectors to comma-separated strings
      safe_collapse <- function(x) {
        if (is.null(x) || length(x) == 0) {
          return("")
        } else if (is.character(x)) {
          return(paste(x, collapse = ", "))
        } else {
          return(as.character(x))
        }
      }
      
      # Prepare response data from reactive values
      # Pre-process all fields to ensure they're in the correct format
      response_data <- list(
        name = if(is.null(form_data$name)) "" else as.character(form_data$name),
        email = if(is.null(form_data$email)) "" else as.character(form_data$email),
        school_name = if(is.null(form_data$school_name)) "" else as.character(form_data$school_name),
        profile_picture = form_data$profile_picture,  # Keep the full file upload object
        fields = if(is.null(form_data$fields)) "" else as.character(form_data$fields),
        environment = safe_collapse(form_data$environment),
        guidance = safe_collapse(form_data$guidance),
        mentorship_type = if(is.null(form_data$mentorship_type)) "" else as.character(form_data$mentorship_type),
        feedback_style = if(is.null(form_data$feedback_style)) "" else as.character(form_data$feedback_style),
        comm_style = safe_collapse(form_data$comm_style),
        frequency = if(is.null(form_data$frequency)) "" else as.character(form_data$frequency),
        values = safe_collapse(form_data$values),
        challenges = if(is.null(form_data$challenges)) "" else as.character(form_data$challenges),
        outcomes = safe_collapse(form_data$outcomes),
        additional = if(is.null(form_data$additional)) "" else as.character(form_data$additional)
      )
      
      # Save to database
      tryCatch({
        # Pre-process the data to ensure all fields are properly formatted
        # This bypasses potential issues in save_questionnaire_response
        
        # Handle profile picture
        profile_picture_blob <- NULL
        profile_picture_type <- NULL
        if (!is.null(form_data$profile_picture) && 
            is.data.frame(form_data$profile_picture) &&
            nrow(form_data$profile_picture) > 0 &&
            !is.null(form_data$profile_picture$datapath[1]) &&
            file.exists(form_data$profile_picture$datapath[1])) {
          profile_picture_blob <- readBin(form_data$profile_picture$datapath[1],
                                          "raw",
                                          file.info(form_data$profile_picture$datapath[1])$size)
          profile_picture_type <- tools::file_ext(form_data$profile_picture$name[1])
        }
        
        # Insert directly into database
        dbExecute(con,
                  "INSERT INTO student_responses 
           (name, email, school_name, profile_picture, profile_picture_type, fields, environment, guidance,
            mentorship_type, feedback_style, comm_style, frequency,
            personal_values, challenges, outcomes, additional_info)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                  params = list(
                    as.character(response_data$name)[1],
                    as.character(response_data$email)[1],
                    as.character(response_data$school_name)[1],
                    list(profile_picture_blob),  # Wrap blob in list for proper handling
                    if(is.null(profile_picture_type)) NA_character_ else as.character(profile_picture_type)[1],
                    as.character(response_data$fields)[1],
                    as.character(response_data$environment)[1],
                    as.character(response_data$guidance)[1],
                    as.character(response_data$mentorship_type)[1],
                    as.character(response_data$feedback_style)[1],
                    as.character(response_data$comm_style)[1],
                    as.character(response_data$frequency)[1],
                    as.character(response_data$values)[1],
                    as.character(response_data$challenges)[1],
                    as.character(response_data$outcomes)[1],
                    as.character(response_data$additional)[1]
                  )
        )
        
        # Debug: Log successful save
        message("Data successfully saved to database at: ", Sys.time())
        
        # Prepare student answers for recommender (keep as lists for the recommender)
        student_answers <- list(
          name = form_data$name,
          email = form_data$email,
          school_name = form_data$school_name,
          fields = form_data$fields,
          environment = form_data$environment,
          guidance = form_data$guidance,
          mentorship_type = form_data$mentorship_type,
          feedback_style = form_data$feedback_style,
          comm_style = form_data$comm_style,
          frequency = form_data$frequency,
          personal_values = form_data$values,
          challenges = form_data$challenges,
          outcomes = form_data$outcomes,
          additional_info = form_data$additional
        )
        
        # Get mentor matches
        embedding_system <- default_embedding_system(con)
        recs <- get_mentor_recommendations(student_answers, embedding_system, top_k = 3)
        dbDisconnect(con)
        mentor_matches(recs)
        
        # Reset form data after successful save
        for (field in names(form_data)) {
          form_data[[field]] <- NULL
        }
        preview_image(NULL)
        
    # Close the modal
    removeModal()
    
        # Show modal with mentor matches
        showModal(
          modalDialog(
            title = "Your Mentor Matches",
            size = "l",
            div(
              lapply(seq_along(recs), function(i) {
                mentor <- recs[[i]]
                div(
                  style = "margin-bottom: 25px; border-bottom: 1px solid #eee; padding-bottom: 15px;",
                  fluidRow(
                    column(2,
                           if (!is.null(mentor$image) && mentor$image != "") {
                             img(src = mentor$image, style = "width:80px; height:80px; border-radius:50%; object-fit:cover;")
                           } else {
                             div(style = "width:80px; height:80px; border-radius:50%; background-color:#ddd;")
                           }
                    ),
                    column(8,
                           h4(mentor$name),
                           p(tags$b(mentor$title)),
                           p(mentor$bio),
                           p(tags$em("Expertise: ", mentor$expertise)),
                           p(tags$span("Match Score: ", round(mentor$score, 2)))
                    ),
                    column(2,
                           actionButton(paste0("select_mentor_", mentor$id), "Select", class = "btn-primary")
                    )
                  )
                )
              })
            ),
            footer = modalButton("Close")
          )
        )
      }, error = function(e) {
        # Close database connection
        dbDisconnect(con)
        
        # Show error message if database save fails
    showModal(
      modalDialog(
            title = "Error",
        div(
              class = "text-center text-danger",
              icon("exclamation-circle", class = "fa-3x mb-3"),
              h4("Failed to save your responses"),
              p("Error details: ", e$message),
              p("Please try again. If the problem persists, contact support."),
          br()
        ),
        footer = modalButton("Close")
      )
    )
        # Log the error with more details
        message("Error saving to database: ", e$message)
        message("Error occurred at: ", Sys.time())
        message("Data structure that caused error:")
        print(str(response_data))
      })
    })
    
    # Dynamically handle mentor selection buttons
    observe({
      recs <- mentor_matches()
      if (!is.null(recs)) {
        lapply(recs, function(mentor) {
          observeEvent(input[[paste0("select_mentor_", mentor$id)]], {
            selected_mentor(mentor)
            removeModal()
            # Show confirmation modal
            showModal(
              modalDialog(
                title = paste("You selected", mentor$name),
                size = "m",
                div(
                  if (!is.null(mentor$image) && mentor$image != "") {
                    img(src = mentor$image, style = "width:100px; height:100px; border-radius:50%; object-fit:cover; margin-bottom:10px;")
                  } else {
                    div(style = "width:100px; height:100px; border-radius:50%; background-color:#ddd; margin-bottom:10px;")
                  },
                  h4(mentor$name),
                  p(tags$b(mentor$title)),
                  p(mentor$bio),
                  p(tags$em("Expertise: ", mentor$expertise)),
                  p(tags$span("Match Score: ", round(mentor$score, 2))),
                  br(),
                  p("An email will be sent to your mentor to notify them of your interest.")
                ),
                footer = tagList(
                  actionButton(ns("confirm_mentor_choice"), "Confirm & Send Email", class = "btn-success"),
                  actionButton(ns("cancel_mentor_selection"), "Cancel", class = "btn-secondary")
                )
              )
            )
          }, ignoreInit = TRUE)
        })
      }
    })
    
    # Handle cancel on mentor selection confirmation modal
    observeEvent(input$ns("cancel_mentor_selection"), {
      removeModal()
      recs <- mentor_matches()
      if (!is.null(recs)) {
        showModal(
          modalDialog(
            title = "Your Mentor Matches",
            size = "l",
            div(
              lapply(seq_along(recs), function(i) {
                mentor <- recs[[i]]
                div(
                  style = "margin-bottom: 25px; border-bottom: 1px solid #eee; padding-bottom: 15px;",
                  fluidRow(
                    column(2,
                           if (!is.null(mentor$image) && mentor$image != "") {
                             img(src = mentor$image, style = "width:80px; height:80px; border-radius:50%; object-fit:cover;")
                           } else {
                             div(style = "width:80px; height:80px; border-radius:50%; background-color:#ddd;")
                           }
                    ),
                    column(8,
                           h4(mentor$name),
                           p(tags$b(mentor$title)),
                           p(mentor$bio),
                           p(tags$em("Expertise: ", mentor$expertise)),
                           p(tags$span("Match Score: ", round(mentor$score, 2)))
                    ),
                    column(2,
                           actionButton(paste0("select_mentor_", mentor$id), "Select", class = "btn-primary")
                    )
                  )
                )
              })
            ),
            footer = modalButton("Close")
          )
        )
      }
    })
    
    # Handle confirmation and send email
    observeEvent(input$ns("confirm_mentor_choice"), {
      mentor <- selected_mentor()
      if (!is.null(mentor)) {
        # Get current form data values for email
        student_name <- if(is.null(form_data$name) || form_data$name == "") "Student" else form_data$name
        student_email <- if(is.null(form_data$email) || form_data$email == "") "no-email@example.com" else form_data$email
        
        # Compose a message for the mentor
        mentor_message <- paste(
          "Hi", mentor$name, ",\n",
          "You have been selected as a mentor by", student_name, ".\n",
          "Student's email:", student_email, "\n",
          "Please log in to MentorMatchAI to view more details."
        )
        
        # Send the email to the mentor
        tryCatch({
          send_email_to_mentor(
            student_name = student_name,
            student_email = student_email,
            mentor_email = mentor$email,
            mentor_name = mentor$name,
            mentor_message = mentor_message
          )
          # Send confirmation to the student
          timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
          send_confirmation_to_student(
            student_name = student_name,
            student_email = student_email,
            mentor_name = mentor$name,
            timestamp = timestamp
          )
          # Record the match in mentor_matches table
          con2 <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
          student_id <- dbGetQuery(con2, "SELECT id FROM student_responses WHERE email = ? ORDER BY submission_date DESC LIMIT 1", params = list(student_email))$id
          dbExecute(con2, "INSERT INTO mentor_matches (student_id, mentor_id) VALUES (?, ?)", params = list(student_id, mentor$id))
          dbDisconnect(con2)
          showNotification(paste("Email sent to", mentor$name, "(", mentor$email, ") and confirmation sent to student."), type = "message")
        }, error = function(e) {
          showNotification(paste("Error sending email:", e$message), type = "error")
        })
        removeModal()
      }
    })
  })
}