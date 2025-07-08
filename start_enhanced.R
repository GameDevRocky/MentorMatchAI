#!/usr/bin/env Rscript

# MentorMatch AI Enhanced - Startup Script

cat("🎯 Starting MentorMatch AI Enhanced...\n")

# Load environment variables
if (file.exists(".env")) {
  readRenviron(".env")
  cat("✅ Loaded environment configuration\n")
} else {
  cat("⚠️  No .env file found. Using default configuration\n")
  cat("   Copy env.example to .env and configure for production\n")
}

# Set default values
port <- as.numeric(Sys.getenv("APP_PORT", "3851"))
host <- Sys.getenv("APP_HOST", "127.0.0.1")

# Load required libraries
suppressPackageStartupMessages({
  library(shiny)
})

cat("🚀 Launching application on", paste0("http://", host, ":", port), "\n")
cat("🔐 Admin credentials: admin / mentormatch2024\n")
cat("📧 SMTP:", if (Sys.getenv("ENABLE_SMTP", "FALSE") == "TRUE") "Enabled" else "Console mode", "\n")

# Run the application
runApp("app_enhanced.R", host = host, port = port, launch.browser = TRUE)

