library(shiny)
library(bslib)
library(DT)
library(shinyjs)

# Sample email data
sample_emails <- data.frame(
  id = 1:5,
  from = c("john.doe@email.com", "jane.smith@email.com", "support@company.com", 
           "newsletter@news.com", "team@project.com"),
  to = rep("you@email.com", 5),
  subject = c("Meeting Tomorrow", "Project Update", "Account Information", 
              "Weekly Newsletter", "Team Lunch"),
  body = c("Hi, just wanted to confirm our meeting tomorrow at 2 PM.",
           "The project is progressing well. Please review the attached files.",
           "Your account information has been updated successfully.",
           "Here's your weekly newsletter with the latest updates.",
           "Don't forget about the team lunch this Friday!"),
  date = c("2024-01-15 09:30", "2024-01-14 14:22", "2024-01-14 11:15", 
           "2024-01-13 08:00", "2024-01-12 16:45"),
  read = c(FALSE, TRUE, FALSE, TRUE, TRUE),
  folder = rep("inbox", 5),
  stringsAsFactors = FALSE
)

# Initialize sent emails
sent_emails <- data.frame(
  id = integer(0),
  from = character(0),
  to = character(0),
  subject = character(0),
  body = character(0),
  date = character(0),
  read = logical(0),
  folder = character(0),
  stringsAsFactors = FALSE
)

# Initialize drafts
draft_emails <- data.frame(
  id = integer(0),
  from = character(0),
  to = character(0),
  subject = character(0),
  body = character(0),
  date = character(0),
  read = logical(0),
  folder = character(0),
  stringsAsFactors = FALSE
)

ui <- page_sidebar(
  title = "Email Client",
  theme = bs_theme(bootswatch = "flatly"),
  
  sidebar = sidebar(
    width = 250,
    h4("Folders", class = "text-primary"),
    div(
      actionButton("inbox_btn", "📥 Inbox", 
                   class = "btn-primary w-100 mb-2 text-start"),
      actionButton("sent_btn", "📤 Sent", 
                   class = "btn-outline-secondary w-100 mb-2 text-start"),
      actionButton("drafts_btn", "📝 Drafts", 
                   class = "btn-outline-secondary w-100 mb-2 text-start"),
      actionButton("compose_btn", "✏️ Compose", 
                   class = "btn-success w-100 mb-3")
    ),
    hr(),
    div(id = "folder_info",
        h6("Inbox", class = "text-muted"),
        p("5 messages", class = "small text-muted")
    ),
    hr(),
    div(
      h6("Account", class = "text-muted"),
      p("you@email.com", class = "small text-muted")
    )
  ),
  
  # Main content area
  div(
    # Email list view
    div(id = "email_list",
        card(
          card_header(
            div(class = "d-flex justify-content-between align-items-center",
                div(id = "folder_title", "Inbox"),
                div(
                  actionButton("refresh_btn", "🔄 Refresh", 
                               class = "btn-outline-primary btn-sm"),
                  actionButton("delete_btn", "🗑️ Delete", 
                               class = "btn-outline-danger btn-sm ms-2")
                )
            )
          ),
          card_body(
            DT::dataTableOutput("email_table")
          )
        )
    ),
    
    # Email detail view
    div(id = "email_detail", style = "display: none;",
        card(
          card_header(
            div(class = "d-flex justify-content-between align-items-center",
                div(id = "email_subject", class = "h5"),
                div(
                  actionButton("reply_btn", "↩️ Reply", class = "btn-outline-primary btn-sm me-2"),
                  actionButton("forward_btn", "↪️ Forward", class = "btn-outline-secondary btn-sm me-2"),
                  actionButton("back_btn", "← Back", class = "btn-outline-secondary btn-sm")
                )
            )
          ),
          card_body(
            div(class = "mb-3 p-3 bg-light rounded",
                div(class = "row mb-2",
                    div(class = "col-2", strong("From:")),
                    div(class = "col-10", span(id = "email_from"))
                ),
                div(class = "row mb-2",
                    div(class = "col-2", strong("To:")),
                    div(class = "col-10", span(id = "email_to"))
                ),
                div(class = "row",
                    div(class = "col-2", strong("Date:")),
                    div(class = "col-10", span(id = "email_date"))
                )
            ),
            hr(),
            div(id = "email_body", 
                style = "white-space: pre-wrap; padding: 15px; min-height: 200px; border: 1px solid #dee2e6; border-radius: 5px; background-color: #fff;")
          )
        )
    ),
    
    # Compose email view
    div(id = "compose_view", style = "display: none;",
        card(
          card_header(
            div(class = "d-flex justify-content-between align-items-center",
                h5(id = "compose_title", "✏️ Compose New Email"),
                actionButton("cancel_compose", "Cancel", class = "btn-outline-secondary btn-sm")
            )
          ),
          card_body(
            div(class = "mb-3",
                textInput("compose_to", "To:", placeholder = "recipient@email.com", width = "100%")
            ),
            div(class = "mb-3",
                textInput("compose_subject", "Subject:", placeholder = "Email subject", width = "100%")
            ),
            div(class = "mb-3",
                textAreaInput("compose_body", "Message:", 
                              placeholder = "Type your message here...",
                              rows = 12, width = "100%")
            ),
            div(class = "d-flex gap-2",
                actionButton("send_email", "📤 Send", class = "btn-primary"),
                actionButton("save_draft", "💾 Save Draft", class = "btn-outline-secondary")
            ),
            # Status messages
            div(id = "compose_status", class = "mt-3")
          )
        )
    )
  ),
  
  useShinyjs()
)

server <- function(input, output, session) {
  # Reactive values to store email data
  emails <- reactiveVal(sample_emails)
  current_folder <- reactiveVal("inbox")
  sent_emails_data <- reactiveVal(sent_emails)
  draft_emails_data <- reactiveVal(draft_emails)
  compose_mode <- reactiveVal("new")  # "new", "reply", "forward"
  reply_to_email <- reactiveVal(NULL)
  
  # Function to get emails for current folder
  current_emails <- reactive({
    if (current_folder() == "inbox") {
      emails()
    } else if (current_folder() == "sent") {
      sent_emails_data()
    } else if (current_folder() == "drafts") {
      draft_emails_data()
    }
  })
  
  # Function to generate email ID
  generate_email_id <- function() {
    max_id <- 0
    if (nrow(emails()) > 0) max_id <- max(max_id, max(emails()$id))
    if (nrow(sent_emails_data()) > 0) max_id <- max(max_id, max(sent_emails_data()$id))
    if (nrow(draft_emails_data()) > 0) max_id <- max(max_id, max(draft_emails_data()$id))
    return(max_id + 1)
  }
  
  # Function to validate email address
  validate_email <- function(email) {
    grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", email)
  }
  
  # Render email table
  output$email_table <- DT::renderDataTable({
    email_data <- current_emails()
    
    if (nrow(email_data) == 0) {
      return(data.frame(
        From = character(0),
        Subject = character(0),
        Date = character(0)
      ))
    }
    
    display_data <- data.frame(
      From = if (current_folder() == "sent") email_data$to else email_data$from,
      Subject = email_data$subject,
      Date = email_data$date
    )
    
    # Add styling for unread emails in inbox
    if (current_folder() == "inbox") {
      display_data$Subject <- ifelse(
        !email_data$read,
        paste0("<strong>", display_data$Subject, "</strong>"),
        display_data$Subject
      )
    }
    
    display_data
  }, 
  options = list(
    pageLength = 15,
    searching = TRUE,
    lengthChange = FALSE,
    info = TRUE,
    columnDefs = list(
      list(width = "30%", targets = 0),
      list(width = "50%", targets = 1),
      list(width = "20%", targets = 2)
    ),
    language = list(
      search = "Search emails:",
      emptyTable = "No emails in this folder"
    )
  ),
  selection = "single",
  escape = FALSE,
  rownames = FALSE
  )
  
  # Handle folder navigation
  observeEvent(input$inbox_btn, {
    current_folder("inbox")
    show("email_list")
    hide("email_detail")
    hide("compose_view")
    
    # Update button styles
    runjs("$('#inbox_btn').removeClass('btn-outline-primary').addClass('btn-primary');")
    runjs("$('#sent_btn').removeClass('btn-primary').addClass('btn-outline-secondary');")
    runjs("$('#drafts_btn').removeClass('btn-primary').addClass('btn-outline-secondary');")
    
    # Update folder info
    email_count <- nrow(emails())
    unread_count <- sum(!emails()$read)
    folder_info <- if (unread_count > 0) {
      paste0(email_count, " messages (", unread_count, " unread)")
    } else {
      paste(email_count, "messages")
    }
    
    runjs(paste0("$('#folder_info').html('<h6 class=\"text-muted\">Inbox</h6><p class=\"small text-muted\">", folder_info, "</p>');"))
    runjs("$('#folder_title').text('Inbox');")
  })
  
  observeEvent(input$sent_btn, {
    current_folder("sent")
    show("email_list")
    hide("email_detail")
    hide("compose_view")
    
    # Update button styles
    runjs("$('#sent_btn').removeClass('btn-outline-secondary').addClass('btn-primary');")
    runjs("$('#inbox_btn').removeClass('btn-primary').addClass('btn-outline-primary');")
    runjs("$('#drafts_btn').removeClass('btn-primary').addClass('btn-outline-secondary');")
    
    # Update folder info
    email_count <- nrow(sent_emails_data())
    folder_info <- paste(email_count, "messages")
    
    runjs(paste0("$('#folder_info').html('<h6 class=\"text-muted\">Sent</h6><p class=\"small text-muted\">", folder_info, "</p>');"))
    runjs("$('#folder_title').text('Sent');")
  })
  
  observeEvent(input$drafts_btn, {
    current_folder("drafts")
    show("email_list")
    hide("email_detail")
    hide("compose_view")
    
    # Update button styles
    runjs("$('#drafts_btn').removeClass('btn-outline-secondary').addClass('btn-primary');")
    runjs("$('#inbox_btn').removeClass('btn-primary').addClass('btn-outline-primary');")
    runjs("$('#sent_btn').removeClass('btn-primary').addClass('btn-outline-secondary');")
    
    # Update folder info
    email_count <- nrow(draft_emails_data())
    folder_info <- paste(email_count, "drafts")
    
    runjs(paste0("$('#folder_info').html('<h6 class=\"text-muted\">Drafts</h6><p class=\"small text-muted\">", folder_info, "</p>');"))
    runjs("$('#folder_title').text('Drafts');")
  })
  
  observeEvent(input$compose_btn, {
    compose_mode("new")
    hide("email_list")
    hide("email_detail")
    show("compose_view")
    
    # Clear compose form
    updateTextInput(session, "compose_to", value = "")
    updateTextInput(session, "compose_subject", value = "")
    updateTextAreaInput(session, "compose_body", value = "")
    runjs("$('#compose_title').text('✏️ Compose New Email');")
    runjs("$('#compose_status').html('');")
  })
  
  # Handle email selection
  observeEvent(input$email_table_rows_selected, {
    if (length(input$email_table_rows_selected) > 0) {
      selected_row <- input$email_table_rows_selected
      email_data <- current_emails()
      selected_email <- email_data[selected_row, ]
      
      # Update email detail view
      runjs(paste0("$('#email_subject').text('", selected_email$subject, "');"))
      runjs(paste0("$('#email_from').text('", selected_email$from, "');"))
      runjs(paste0("$('#email_to').text('", selected_email$to, "');"))
      runjs(paste0("$('#email_date').text('", selected_email$date, "');"))
      runjs(paste0("$('#email_body').text('", gsub("'", "\\'", selected_email$body), "');"))
      
      # Store current email for reply/forward
      reply_to_email(selected_email)
      
      # Mark as read if it's in inbox
      if (current_folder() == "inbox" && !selected_email$read) {
        current_emails_data <- emails()
        current_emails_data[selected_row, "read"] <- TRUE
        emails(current_emails_data)
      }
      
      hide("email_list")
      show("email_detail")
    }
  })
  
  # Handle reply button
  observeEvent(input$reply_btn, {
    email <- reply_to_email()
    if (!is.null(email)) {
      compose_mode("reply")
      
      # Pre-fill compose form
      updateTextInput(session, "compose_to", value = email$from)
      updateTextInput(session, "compose_subject", value = paste("Re:", email$subject))
      updateTextAreaInput(session, "compose_body", 
                          value = paste0("\n\n--- Original Message ---\n",
                                         "From: ", email$from, "\n",
                                         "Date: ", email$date, "\n",
                                         "Subject: ", email$subject, "\n\n",
                                         email$body))
      
      runjs("$('#compose_title').text('↩️ Reply to Email');")
      runjs("$('#compose_status').html('');")
      
      hide("email_detail")
      show("compose_view")
    }
  })
  
  # Handle forward button
  observeEvent(input$forward_btn, {
    email <- reply_to_email()
    if (!is.null(email)) {
      compose_mode("forward")
      
      # Pre-fill compose form
      updateTextInput(session, "compose_to", value = "")
      updateTextInput(session, "compose_subject", value = paste("Fwd:", email$subject))
      updateTextAreaInput(session, "compose_body", 
                          value = paste0("\n\n--- Forwarded Message ---\n",
                                         "From: ", email$from, "\n",
                                         "To: ", email$to, "\n",
                                         "Date: ", email$date, "\n",
                                         "Subject: ", email$subject, "\n\n",
                                         email$body))
      
      runjs("$('#compose_title').text('↪️ Forward Email');")
      runjs("$('#compose_status').html('');")
      
      hide("email_detail")
      show("compose_view")
    }
  })
  
  # Handle back button
  observeEvent(input$back_btn, {
    hide("email_detail")
    show("email_list")
  })
  
  # Handle cancel compose
  observeEvent(input$cancel_compose, {
    hide("compose_view")
    show("email_list")
  })
  
  # Handle refresh button
  observeEvent(input$refresh_btn, {
    showNotification("Emails refreshed!", type = "message", duration = 2)
  })
  
  # Handle delete button
  observeEvent(input$delete_btn, {
    if (length(input$email_table_rows_selected) > 0) {
      selected_row <- input$email_table_rows_selected
      
      if (current_folder() == "inbox") {
        current_emails_data <- emails()
        current_emails_data <- current_emails_data[-selected_row, ]
        emails(current_emails_data)
      } else if (current_folder() == "sent") {
        current_emails_data <- sent_emails_data()
        current_emails_data <- current_emails_data[-selected_row, ]
        sent_emails_data(current_emails_data)
      } else if (current_folder() == "drafts") {
        current_emails_data <- draft_emails_data()
        current_emails_data <- current_emails_data[-selected_row, ]
        draft_emails_data(current_emails_data)
      }
      
      showNotification("Email deleted!", type = "warning", duration = 2)
    } else {
      showNotification("Please select an email to delete.", type = "error", duration = 3)
    }
  })
  
  # Handle send email
  observeEvent(input$send_email, {
    # Validate inputs
    if (input$compose_to == "" || input$compose_subject == "" || input$compose_body == "") {
      runjs("$('#compose_status').html('<div class=\"alert alert-danger\">Please fill in all fields.</div>');")
      return()
    }
    
    if (!validate_email(input$compose_to)) {
      runjs("$('#compose_status').html('<div class=\"alert alert-danger\">Please enter a valid email address.</div>');")
      return()
    }
    
    # Create new email
    new_email <- data.frame(
      id = generate_email_id(),
      from = "you@email.com",
      to = input$compose_to,
      subject = input$compose_subject,
      body = input$compose_body,
      date = format(Sys.time(), "%Y-%m-%d %H:%M"),
      read = TRUE,
      folder = "sent",
      stringsAsFactors = FALSE
    )
    
    # Add to sent emails
    sent_data <- sent_emails_data()
    sent_data <- rbind(sent_data, new_email)
    sent_emails_data(sent_data)
    
    # Show success message
    runjs("$('#compose_status').html('<div class=\"alert alert-success\">Email sent successfully!</div>');")
    
    # Clear form after 2 seconds and return to email list
    shinyjs::delay(2000, {
      updateTextInput(session, "compose_to", value = "")
      updateTextInput(session, "compose_subject", value = "")
      updateTextAreaInput(session, "compose_body", value = "")
      runjs("$('#compose_status').html('');")
      hide("compose_view")
      show("email_list")
    })
  })
  
  # Handle save draft
  observeEvent(input$save_draft, {
    if (input$compose_to == "" && input$compose_subject == "" && input$compose_body == "") {
      runjs("$('#compose_status').html('<div class=\"alert alert-warning\">Cannot save empty draft.</div>');")
      return()
    }
    
    # Create new draft
    new_draft <- data.frame(
      id = generate_email_id(),
      from = "you@email.com",
      to = input$compose_to,
      subject = ifelse(input$compose_subject == "", "(No Subject)", input$compose_subject),
      body = input$compose_body,
      date = format(Sys.time(), "%Y-%m-%d %H:%M"),
      read = TRUE,
      folder = "drafts",
      stringsAsFactors = FALSE
    )
    
    # Add to drafts
    draft_data <- draft_emails_data()
    draft_data <- rbind(draft_data, new_draft)
    draft_emails_data(draft_data)
    
    # Show success message
    runjs("$('#compose_status').html('<div class=\"alert alert-info\">Draft saved successfully!</div>');")
    
    # Clear form after 2 seconds and return to email list
    shinyjs::delay(2000, {
      updateTextInput(session, "compose_to", value = "")
      updateTextInput(session, "compose_subject", value = "")
      updateTextAreaInput(session, "compose_body", value = "")
      runjs("$('#compose_status').html('');")
      hide("compose_view")
      show("email_list")
    })
  })
}

# Run the application
shinyApp(ui = ui, server = server)