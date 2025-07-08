library(DBI)
library(RSQLite)

# Connect to database
con <- dbConnect(RSQLite::SQLite(), "mentormatch.sqlite")

# Drop and recreate students table with new schema
dbExecute(con, "DROP TABLE IF EXISTS students")
dbExecute(con, "CREATE TABLE students (
  id INTEGER PRIMARY KEY,
  name TEXT,
  email TEXT,
  majors TEXT,
  industries TEXT,
  looking_for TEXT,
  comm TEXT,
  aspects TEXT,
  challenge TEXT,
  matched_mentor_id INTEGER
)")

# Drop and recreate mentors table with new schema
dbExecute(con, "DROP TABLE IF EXISTS mentors")
dbExecute(con, "CREATE TABLE mentors (
  id INTEGER PRIMARY KEY,
  name TEXT,
  email TEXT,
  majors TEXT,
  industries TEXT,
  offers TEXT,
  comm TEXT,
  aspects TEXT,
  bio TEXT
)")

# Verify tables were created
students_cols <- dbListFields(con, "students")
mentors_cols <- dbListFields(con, "mentors")
cat("Students table columns:", paste(students_cols, collapse=", "), "\n")
cat("Mentors table columns:", paste(mentors_cols, collapse=", "), "\n")

dbDisconnect(con)
cat("Tables updated successfully!\n") 