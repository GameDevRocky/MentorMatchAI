library(shiny)

# Define UI for application
ui <- fluidPage(
  # Application title
  titlePanel("Dynamic UI Example: Data Analysis Tool"),
  
  # Add some styling for better appearance
  tags$head(
    tags$style(HTML("
      .well {
        background-color: #f5f5f5;
        border: 1px solid #e3e3e3;
        border-radius: 4px;
        margin-top: 20px;
      }
      .dynamic-content {
        margin-top: 20px;
        padding: 15px;
        background-color: #e8f4fd;
        border-radius: 5px;
      }
    "))
  ),
  
  # Sidebar layout
  sidebarLayout(
    sidebarPanel(
      # Main selection that will control the UI
      selectInput("analysis_type",
                  "Select Analysis Type:",
                  choices = c("Descriptive Statistics" = "descriptive",
                              "Visualization" = "visualization",
                              "Regression Analysis" = "regression",
                              "Time Series" = "timeseries"),
                  selected = "descriptive"),
      
      # This is where dynamic UI elements will appear based on selection
      uiOutput("dynamic_controls"),
      
      # Add an action button to trigger analysis
      br(),
      actionButton("analyze", "Run Analysis", class = "btn-primary")
    ),
    
    # Main panel for displaying results
    mainPanel(
      # Dynamic output area that changes based on selection
      uiOutput("dynamic_output")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Create dynamic UI controls based on analysis type selection
  output$dynamic_controls <- renderUI({
    # Use a switch statement to handle different cases
    switch(input$analysis_type,
           
           # Controls for descriptive statistics
           "descriptive" = {
             tagList(
               h4("Descriptive Statistics Options"),
               # Variable selection for analysis
               selectInput("desc_variable",
                           "Select Variable:",
                           choices = c("Sepal.Length", "Sepal.Width", 
                                       "Petal.Length", "Petal.Width"),
                           selected = "Sepal.Length"),
               # Checkbox group for statistics to calculate
               checkboxGroupInput("desc_stats",
                                  "Statistics to Calculate:",
                                  choices = c("Mean" = "mean",
                                              "Median" = "median",
                                              "Standard Deviation" = "sd",
                                              "Min/Max" = "minmax",
                                              "Quartiles" = "quartiles"),
                                  selected = c("mean", "median"))
             )
           },
           
           # Controls for visualization
           "visualization" = {
             tagList(
               h4("Visualization Options"),
               # Plot type selection
               radioButtons("plot_type",
                            "Select Plot Type:",
                            choices = c("Histogram" = "hist",
                                        "Scatter Plot" = "scatter",
                                        "Box Plot" = "box"),
                            selected = "hist"),
               # Additional controls appear based on plot type
               conditionalPanel(
                 condition = "input.plot_type == 'hist'",
                 selectInput("hist_var",
                             "Variable for Histogram:",
                             choices = c("Sepal.Length", "Sepal.Width", 
                                         "Petal.Length", "Petal.Width")),
                 sliderInput("bins",
                             "Number of Bins:",
                             min = 5, max = 50, value = 20)
               ),
               conditionalPanel(
                 condition = "input.plot_type == 'scatter'",
                 selectInput("scatter_x",
                             "X Variable:",
                             choices = c("Sepal.Length", "Sepal.Width", 
                                         "Petal.Length", "Petal.Width")),
                 selectInput("scatter_y",
                             "Y Variable:",
                             choices = c("Sepal.Length", "Sepal.Width", 
                                         "Petal.Length", "Petal.Width"),
                             selected = "Sepal.Width")
               ),
               conditionalPanel(
                 condition = "input.plot_type == 'box'",
                 selectInput("box_var",
                             "Variable for Box Plot:",
                             choices = c("Sepal.Length", "Sepal.Width", 
                                         "Petal.Length", "Petal.Width"))
               )
             )
           },
           
           # Controls for regression analysis
           "regression" = {
             tagList(
               h4("Regression Options"),
               # Dependent variable selection
               selectInput("reg_dependent",
                           "Dependent Variable (Y):",
                           choices = c("Sepal.Length", "Sepal.Width", 
                                       "Petal.Length", "Petal.Width")),
               # Independent variables selection
               checkboxGroupInput("reg_independent",
                                  "Independent Variables (X):",
                                  choices = c("Sepal.Length", "Sepal.Width", 
                                              "Petal.Length", "Petal.Width"),
                                  selected = "Petal.Length"),
               # Model options
               checkboxInput("reg_intercept",
                             "Include Intercept",
                             value = TRUE),
               checkboxInput("reg_summary",
                             "Show Full Summary",
                             value = TRUE)
             )
           },
           
           # Controls for time series
           "timeseries" = {
             tagList(
               h4("Time Series Options"),
               # Data generation options (for demo purposes)
               numericInput("ts_length",
                            "Length of Time Series:",
                            value = 100, min = 50, max = 500),
               selectInput("ts_pattern",
                           "Pattern Type:",
                           choices = c("Trend" = "trend",
                                       "Seasonal" = "seasonal",
                                       "Random Walk" = "random"),
                           selected = "trend"),
               # Analysis options
               checkboxInput("ts_decompose",
                             "Show Decomposition",
                             value = FALSE),
               checkboxInput("ts_acf",
                             "Show ACF Plot",
                             value = FALSE)
             )
           }
    )
  })
  
  # Create dynamic output based on analysis type and user inputs
  output$dynamic_output <- renderUI({
    # Only show output after clicking analyze button
    if (input$analyze == 0) {
      return(
        div(class = "dynamic-content",
            h3("Welcome to the Dynamic UI Demo!"),
            p("This app demonstrates how Shiny UIs can change based on user selections."),
            p("Choose an analysis type from the dropdown and notice how the controls change."),
            p("Click 'Run Analysis' to see the results.")
        )
      )
    }
    
    # Isolate to only update when analyze button is clicked
    isolate({
      switch(input$analysis_type,
             
             # Output for descriptive statistics
             "descriptive" = {
               tagList(
                 h3("Descriptive Statistics Results"),
                 verbatimTextOutput("desc_output"),
                 plotOutput("desc_plot")
               )
             },
             
             # Output for visualization
             "visualization" = {
               tagList(
                 h3("Visualization Results"),
                 plotOutput("viz_output", height = "400px"),
                 verbatimTextOutput("viz_summary")
               )
             },
             
             # Output for regression
             "regression" = {
               tagList(
                 h3("Regression Analysis Results"),
                 verbatimTextOutput("reg_output"),
                 plotOutput("reg_plots", height = "600px")
               )
             },
             
             # Output for time series
             "timeseries" = {
               tagList(
                 h3("Time Series Analysis Results"),
                 plotOutput("ts_plot", height = "400px"),
                 conditionalPanel(
                   condition = "input.ts_decompose == true",
                   plotOutput("ts_decomp", height = "400px")
                 ),
                 conditionalPanel(
                   condition = "input.ts_acf == true",
                   plotOutput("ts_acf_plot", height = "300px")
                 )
               )
             }
      )
    })
  })
  
  # Render descriptive statistics output
  output$desc_output <- renderPrint({
    req(input$desc_variable, input$desc_stats)
    
    # Use iris dataset for demonstration
    data <- iris[[input$desc_variable]]
    
    cat("Variable:", input$desc_variable, "\n")
    cat("Sample size:", length(data), "\n\n")
    
    # Calculate selected statistics
    if ("mean" %in% input$desc_stats) {
      cat("Mean:", round(mean(data), 3), "\n")
    }
    if ("median" %in% input$desc_stats) {
      cat("Median:", round(median(data), 3), "\n")
    }
    if ("sd" %in% input$desc_stats) {
      cat("Standard Deviation:", round(sd(data), 3), "\n")
    }
    if ("minmax" %in% input$desc_stats) {
      cat("Minimum:", round(min(data), 3), "\n")
      cat("Maximum:", round(max(data), 3), "\n")
    }
    if ("quartiles" %in% input$desc_stats) {
      q <- quantile(data)
      cat("1st Quartile:", round(q[2], 3), "\n")
      cat("3rd Quartile:", round(q[4], 3), "\n")
    }
  })
  
  # Render descriptive statistics plot
  output$desc_plot <- renderPlot({
    req(input$desc_variable)
    data <- iris[[input$desc_variable]]
    
    # Create a simple histogram with density overlay
    hist(data, 
         main = paste("Distribution of", input$desc_variable),
         xlab = input$desc_variable,
         col = "lightblue",
         border = "darkblue",
         probability = TRUE)
    
    # Add density curve
    lines(density(data), col = "red", lwd = 2)
  })
  
  # Render visualization output
  output$viz_output <- renderPlot({
    if (input$plot_type == "hist") {
      req(input$hist_var, input$bins)
      hist(iris[[input$hist_var]], 
           breaks = input$bins,
           main = paste("Histogram of", input$hist_var),
           xlab = input$hist_var,
           col = "steelblue",
           border = "white")
      
    } else if (input$plot_type == "scatter") {
      req(input$scatter_x, input$scatter_y)
      plot(iris[[input$scatter_x]], iris[[input$scatter_y]],
           main = paste(input$scatter_x, "vs", input$scatter_y),
           xlab = input$scatter_x,
           ylab = input$scatter_y,
           pch = 19,
           col = factor(iris$Species))
      legend("topright", legend = levels(iris$Species), 
             col = 1:3, pch = 19, bty = "n")
      
    } else if (input$plot_type == "box") {
      req(input$box_var)
      boxplot(iris[[input$box_var]] ~ iris$Species,
              main = paste("Box Plot of", input$box_var, "by Species"),
              xlab = "Species",
              ylab = input$box_var,
              col = c("lightblue", "lightgreen", "lightpink"))
    }
  })
  
  # Render visualization summary
  output$viz_summary <- renderPrint({
    if (input$plot_type == "scatter") {
      req(input$scatter_x, input$scatter_y)
      cor_val <- cor(iris[[input$scatter_x]], iris[[input$scatter_y]])
      cat("Correlation between", input$scatter_x, "and", input$scatter_y, ":", 
          round(cor_val, 3))
    }
  })
  
  # Render regression output
  output$reg_output <- renderPrint({
    req(input$reg_dependent, input$reg_independent)
    
    # Ensure dependent variable is not in independent variables
    indep_vars <- setdiff(input$reg_independent, input$reg_dependent)
    
    if (length(indep_vars) == 0) {
      cat("Please select at least one independent variable different from the dependent variable.")
      return()
    }
    
    # Build formula
    formula_str <- paste(input$reg_dependent, "~", 
                         ifelse(input$reg_intercept, "", "0 +"),
                         paste(indep_vars, collapse = " + "))
    
    # Fit model
    model <- lm(as.formula(formula_str), data = iris)
    
    # Show output based on user preference
    if (input$reg_summary) {
      summary(model)
    } else {
      print(model)
    }
  })
  
  # Render regression diagnostic plots
  output$reg_plots <- renderPlot({
    req(input$reg_dependent, input$reg_independent)
    
    indep_vars <- setdiff(input$reg_independent, input$reg_dependent)
    if (length(indep_vars) == 0) return()
    
    # Build and fit model
    formula_str <- paste(input$reg_dependent, "~", 
                         ifelse(input$reg_intercept, "", "0 +"),
                         paste(indep_vars, collapse = " + "))
    model <- lm(as.formula(formula_str), data = iris)
    
    # Create diagnostic plots
    par(mfrow = c(2, 2))
    plot(model)
  })
  
  # Render time series plot
  output$ts_plot <- renderPlot({
    req(input$ts_length, input$ts_pattern)
    
    # Generate time series data based on pattern
    time <- 1:input$ts_length
    
    if (input$ts_pattern == "trend") {
      ts_data <- 10 + 0.1 * time + rnorm(input$ts_length, sd = 2)
    } else if (input$ts_pattern == "seasonal") {
      ts_data <- 10 + 5 * sin(2 * pi * time / 12) + rnorm(input$ts_length, sd = 1)
    } else {
      ts_data <- cumsum(rnorm(input$ts_length))
    }
    
    # Convert to time series object
    ts_obj <- ts(ts_data, frequency = 12)
    
    # Plot time series
    plot(ts_obj, 
         main = paste("Time Series -", 
                      switch(input$ts_pattern,
                             "trend" = "Trend Pattern",
                             "seasonal" = "Seasonal Pattern",
                             "random" = "Random Walk")),
         ylab = "Value",
         xlab = "Time",
         col = "darkblue",
         lwd = 2)
    grid()
  })
  
  # Render decomposition plot
  output$ts_decomp <- renderPlot({
    req(input$ts_length, input$ts_pattern)
    
    # Generate same time series data
    time <- 1:input$ts_length
    
    if (input$ts_pattern == "trend") {
      ts_data <- 10 + 0.1 * time + rnorm(input$ts_length, sd = 2)
    } else if (input$ts_pattern == "seasonal") {
      ts_data <- 10 + 5 * sin(2 * pi * time / 12) + rnorm(input$ts_length, sd = 1)
    } else {
      ts_data <- cumsum(rnorm(input$ts_length))
    }
    
    ts_obj <- ts(ts_data, frequency = 12)
    
    # Decompose if enough data
    if (input$ts_length >= 24) {
      decomp <- decompose(ts_obj)
      plot(decomp)
    } else {
      plot.new()
      text(0.5, 0.5, "Need at least 24 observations for decomposition", cex = 1.2)
    }
  })
  
  # Render ACF plot
  output$ts_acf_plot <- renderPlot({
    req(input$ts_length, input$ts_pattern)
    
    # Generate same time series data
    time <- 1:input$ts_length
    
    if (input$ts_pattern == "trend") {
      ts_data <- 10 + 0.1 * time + rnorm(input$ts_length, sd = 2)
    } else if (input$ts_pattern == "seasonal") {
      ts_data <- 10 + 5 * sin(2 * pi * time / 12) + rnorm(input$ts_length, sd = 1)
    } else {
      ts_data <- cumsum(rnorm(input$ts_length))
    }
    
    # Create ACF plot
    acf(ts_data, main = "Autocorrelation Function (ACF)")
  })
}

# Run the application
shinyApp(ui = ui, server = server)