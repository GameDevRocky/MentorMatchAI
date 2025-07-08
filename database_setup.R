library(RSQLite)
library(DBI)

# Create database connection
init_database <- function() {
  # Connect to SQLite database (creates if not exists)
  con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")
  
  # Create student_responses table if it doesn't exist
  if (!dbExistsTable(con, "student_responses")) {
    dbExecute(con, "
      CREATE TABLE student_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        name TEXT,
        email TEXT,
        school_name TEXT,
        profile_picture BLOB,
        profile_picture_type TEXT,
        fields TEXT,
        environment TEXT,
        guidance TEXT,
        mentorship_type TEXT,
        feedback_style TEXT,
        comm_style TEXT,
        frequency TEXT,
        personal_values TEXT,
        challenges TEXT,
        outcomes TEXT,
        additional_info TEXT
      )
    ")
    
    # Create uploads directory if it doesn't exist
    if (!dir.exists("www/uploads")) {
      dir.create("www/uploads", recursive = TRUE)
    }
  }
  
  # Create mentor_profiles table if it doesn't exist
  if (!dbExistsTable(con, "mentor_profiles")) {
    dbExecute(con, "
      CREATE TABLE mentor_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        title TEXT,
        expertise TEXT,
        bio TEXT,
        email TEXT,
        image TEXT
      )
    ")
  }
  
  # Insert dummy mentor data if table is empty
  if (dbGetQuery(con, "SELECT COUNT(*) as n FROM mentor_profiles")$n == 0) {
    dbExecute(con, "INSERT INTO mentor_profiles (name, title, expertise, bio, email, image) VALUES
      ('Dr. Jane Smith', 'Senior Data Scientist', 'Machine Learning, Data Analysis, R Programming', 'I have over 10 years of experience in data science and enjoy mentoring new talent in the field.', 'jane.smith@example.com', 'https://randomuser.me/api/portraits/women/44.jpg'),
      ('Sarah Lee', 'Graduate Student', 'Natural Language Processing, Healthcare Analytics', 'PhD student researching NLP applications in healthcare. Seeking guidance on research methods.', 'sarah.lee@example.edu', 'https://randomuser.me/api/portraits/women/22.jpg'),
      ('Michael Chen', 'Software Developer', 'Data Engineering, Software Development', 'Transitioning from web development to data science. Looking for guidance on best practices.', 'mchen@example.com', 'https://randomuser.me/api/portraits/men/53.jpg')
    ")
  }
  
  # Create mentor_matches table if it doesn't exist
  if (!dbExistsTable(con, "mentor_matches")) {
    dbExecute(con, "
      CREATE TABLE mentor_matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        mentor_id INTEGER,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(student_id) REFERENCES student_responses(id),
        FOREIGN KEY(mentor_id) REFERENCES mentor_profiles(id)
      )
    ")
  }
  
  # Return the connection
  return(con)
}

# Function to read file as binary
read_file_binary <- function(filepath) {
  readBin(filepath, "raw", n = file.info(filepath)$size)
}

# Function to save questionnaire responses
save_questionnaire_response <- function(con, response_data) {
  # Convert list elements to character strings where needed
  response_data$environment <- if (is.null(response_data$environment)) "" else paste(response_data$environment, collapse = ", ")
  response_data$guidance <- if (is.null(response_data$guidance)) "" else paste(response_data$guidance, collapse = ", ")
  response_data$comm_style <- if (is.null(response_data$comm_style)) "" else paste(response_data$comm_style, collapse = ", ")
  response_data$values <- if (is.null(response_data$values)) "" else paste(response_data$values, collapse = ", ")
  response_data$outcomes <- if (is.null(response_data$outcomes)) "" else paste(response_data$outcomes, collapse = ", ")

  # Handle profile picture if present and valid
  profile_picture_blob <- NULL
  profile_picture_type <- NULL
  if (!is.null(response_data$profile_picture) &&
      !is.null(response_data$profile_picture$datapath) &&
      file.exists(response_data$profile_picture$datapath)) {
    tmp_blob <- read_file_binary(response_data$profile_picture$datapath)
    if (is.raw(tmp_blob) && length(tmp_blob) > 0) {
      profile_picture_blob <- tmp_blob
      profile_picture_type <- tools::file_ext(response_data$profile_picture$name)
      if (is.null(profile_picture_type) || profile_picture_type == "") profile_picture_type <- NULL
    }
  }

  # Always insert all columns, passing NULL for profile_picture/profile_picture_type if not present
  dbExecute(con,
    "INSERT INTO student_responses 
     (name, email, school_name, profile_picture, profile_picture_type, fields, environment, guidance,
      mentorship_type, feedback_style, comm_style, frequency,
      personal_values, challenges, outcomes, additional_info)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    params = list(
      ifelse(is.null(response_data$name), NA, response_data$name),
      ifelse(is.null(response_data$email), NA, response_data$email),
      ifelse(is.null(response_data$school_name), NA, response_data$school_name),
      profile_picture_blob,
      profile_picture_type,
      ifelse(is.null(response_data$fields), "", response_data$fields),
      response_data$environment,
      response_data$guidance,
      ifelse(is.null(response_data$mentorship_type), "", response_data$mentorship_type),
      ifelse(is.null(response_data$feedback_style), "", response_data$feedback_style),
      response_data$comm_style,
      ifelse(is.null(response_data$frequency), "", response_data$frequency),
      response_data$values,
      ifelse(is.null(response_data$challenges), "", response_data$challenges),
      response_data$outcomes,
      ifelse(is.null(response_data$additional), "", response_data$additional)
    )
  )
}

# Function to retrieve profile picture
get_profile_picture <- function(con, student_id) {
  result <- dbGetQuery(con, 
    "SELECT profile_picture, profile_picture_type 
     FROM student_responses 
     WHERE id = ?", 
    params = list(student_id)
  )
  
  if (nrow(result) > 0 && !is.null(result$profile_picture[[1]])) {
    return(list(
      data = result$profile_picture[[1]],
      type = result$profile_picture_type[[1]]
    ))
  }
  return(NULL)
} 