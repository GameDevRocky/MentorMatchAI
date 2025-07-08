library(shiny)

# --- Extended CSS with support for nested grids ---
bento_style <- function(
    gap = "20px",
    radius = "20px",
    font_size = "14px",
    title_size = "18px",
    card_height = "120px",
    hover_scale = 1.03,
    outer_padding = "25px",
    container_border = TRUE,
    custom_css = NULL
) {
  container_style <- if (container_border) {
    glue::glue("
      .bento-wrapper {{
        border: 2px solid #ccc;
        border-radius: 25px;
        padding: {outer_padding};
        margin: 30px auto;
        max-width: 1200px;
        background-color: #fff;
      }}
    ")
  } else {
    glue::glue(".bento-wrapper {{ padding: {outer_padding}; max-width: 1200px; margin: 30px auto; }}")
  }
  
  glue::glue("
    {container_style}
    .bento-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
      grid-auto-rows: {card_height};
      gap: {gap};
    }}
    .bento-card {{
      background-color: #f5f5f7;
      border-radius: {radius};
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      padding: 20px;
      transition: transform 0.2s ease-in-out;
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
      font-size: {font_size};
    }}
    .bento-card:hover {{
      transform: scale({hover_scale});
    }}
    .card-title {{
      font-size: {title_size};
      font-weight: bold;
      margin-bottom: 10px;
    }}
    .card-content {{
      flex-grow: 1;
    }}
    .size-1x1 {{ grid-column: span 1; grid-row: span 1; }}
    .size-2x1 {{ grid-column: span 2; grid-row: span 1; }}
    .size-1x2 {{ grid-column: span 1; grid-row: span 2; }}
    .size-2x2 {{ grid-column: span 2; grid-row: span 2; }}

    .bento-card .bento-grid {{
      grid-auto-rows: 80px;
      gap: 10px;
      padding: 0;
    }}
    {custom_css %||% ""}
  ")
}

# --- Bento Card Builder with Nesting Support ---
bento_card <- function(title = NULL, content = NULL, color = "#ffffff", size = "size-1x1", children = NULL) {
  div(class = paste("bento-card", size), style = paste0("background-color:", color, ";"),
      if (!is.null(title)) div(class = "card-title", title),
      div(class = "card-content",
          if (!is.null(content)) content,
          if (!is.null(children)) children
      )
  )
}

# --- Example App with Nested Bento Cards ---
ui <- fluidPage(
  tags$head(tags$style(HTML(bento_style()))),
  
  h2("Nested Bento Layout", align = "center"),
  
  div(class = "bento-wrapper",
      div(class = "bento-grid",
          bento_card("Overview", "System stable", "#E0F2FE", "size-2x2"),
          bento_card("Engagement", "Up 60%", "#FEF9C3", "size-1x1"),
          
          bento_card(title = "Project Alpha", size = "size-2x2", color = "#EDE9FE",
                     children = div(class = "bento-grid",
                                    bento_card("Phase 1", "Completed", "#D1FAE5", "size-1x1"),
                                    bento_card("Phase 2", "In Progress", "#FCD34D", "size-1x1"),
                                    bento_card("Budget", "$15K", "#F3F4F6", "size-2x1")
                     )
          ),
          
          bento_card("Blog", "Updated weekly", "#E5E5E5", "size-1x1"),
          bento_card("Release", "v2.1.0", "#FECACA", "size-1x1")
      )
  )
)

server <- function(input, output, session) {}

shinyApp(ui, server)
