library(shiny)
library(bslib)
library(DBI)
library(RSQLite)

mentor_profile_ui <- function(id, mentor_id = NULL) {
  ns <- NS(id)
  page_fluid(
  theme = bs_theme(bootswatch = "flatly"),
  page_navbar(
    title = "Mentor Dashboard",
    selected = "Dashboard",
    nav_panel(
      title = "Dashboard",
      layout_columns(
        col_widths = c(4, 8),
        card(
          card_header("My Profile"),
          card_body(
              if (is.null(mentor_id)) selectInput(ns("mentor_id"), "Select Your Mentor Profile (for demo):", choices = NULL),
              uiOutput(ns("mentor_profile_ui"))
          )
        ),
        card(
          card_header("My Mentees"),
          card_body(
              uiOutput(ns("mentees_container"))
            )
          )
        )
      )
    )
  )
}

mentor_profile_server <- function(id, mentor_id = reactive(NULL)) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
    mentors <- dbGetQuery(con, "SELECT * FROM mentor_profiles")
    dbDisconnect(con)
    
    observe({
      if (is.null(mentor_id()) || is.na(mentor_id())) {
        updateSelectInput(session, "mentor_id", choices = setNames(mentors$id, mentors$name), selected = mentors$id[1])
      }
    })

    # Determine which mentor ID to use
    current_mentor_id <- reactive({
      if (!is.null(mentor_id()) && !is.na(mentor_id())) {
        mentor_id()
      } else {
        input$mentor_id
      }
    })

    output$mentor_profile_ui <- renderUI({
      req(current_mentor_id())
      mentor <- mentors[mentors$id == current_mentor_id(), ]
      tagList(
          div(
          style = "text-align: center;",
          img(src = mentor$image, style = "width: 150px; height: 150px; border-radius: 50%; object-fit: cover;")
          ),
        h3(mentor$name, style = "text-align: center;"),
        p(mentor$title, style = "text-align: center;"),
            tags$hr(),
        h4("Expertise"),
            tags$ul(
          lapply(strsplit(mentor$expertise, ", ?")[[1]], function(exp) tags$li(exp))
            ),
        p(mentor$bio),
        p(tags$strong("Contact: "), mentor$email)
      )
    })

    output$mentees_container <- renderUI({
      req(current_mentor_id())
      con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
      mentees <- tryCatch({
        dbGetQuery(con, "
          SELECT s.* FROM mentor_matches m
          JOIN student_responses s ON m.student_id = s.id
          WHERE m.mentor_id = ?
          ORDER BY m.timestamp DESC
        ", params = list(current_mentor_id()))
      }, error = function(e) data.frame())
      dbDisconnect(con)
      if (nrow(mentees) == 0) {
        return(div("No mentees have matched with you yet."))
      }
      tagList(
        lapply(seq_len(nrow(mentees)), function(i) {
          mentee <- mentees[i, ]
          card(
            class = "mb-3 mentee-card",
            card_body(
              layout_columns(
                col_widths = c(2, 10),
                div(
                  if (!is.null(mentee$profile_picture) && length(mentee$profile_picture) > 0) {
                    icon("user", class = "fa-2x")
                  } else {
                    icon("user", class = "fa-2x")
                  }
                ),
                div(
                  h4(mentee$name),
                  p(mentee$school_name),
                  p(tags$em(substr(mentee$fields, 1, 100), "...")),
                  p(tags$strong("Email: "), mentee$email)
                )
        )
      )
    )
  })
      )
    })
  })
}
