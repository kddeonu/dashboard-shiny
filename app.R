# Load required libraries
library(shiny)
library(DBI)
library(RPostgreSQL)
library(DT)
library(ggplot2)
library(dplyr)

# Database connection function
get_data <- function() {
  tryCatch({
    # Connect to database
    conn <- dbConnect(
      PostgreSQL(),
      host = "yamanote.proxy.rlwy.net",
      port = 58101,
      dbname = "railway",
      user = "postgres",
      password = "qbOqtrqNgcbMMhDmvHJbXdfKRfgZDxdk"
    )
    
    # Get data
    data <- dbGetQuery(conn, "SELECT * FROM data_gabungan_rating_konsumer LIMIT 500")
    
    # Close connection
    dbDisconnect(conn)
    
    return(data)
  }, error = function(e) {
    return(data.frame(Error = paste("Connection failed:", e$message)))
  })
}

# UI
ui <- fluidPage(
  titlePanel("Dashboard Konsumen Railway"),
  
  # CSS for better styling
  tags$head(
    tags$style(HTML("
      body { font-family: Arial, sans-serif; }
      .metric-box { 
        background: #f8f9fa; 
        border: 1px solid #dee2e6; 
        border-radius: 8px; 
        padding: 20px; 
        text-align: center; 
        margin: 10px 0;
      }
      .metric-number { 
        font-size: 2em; 
        font-weight: bold; 
        color: #007bff; 
      }
      .metric-label { 
        color: #6c757d; 
        margin-top: 5px; 
      }
    "))
  ),
  
  # Main content
  fluidRow(
    column(12,
           h3("📊 Ringkasan Data"),
           
           # Metrics
           fluidRow(
             column(3,
                    div(class = "metric-box",
                        div(class = "metric-number", textOutput("total_records")),
                        div(class = "metric-label", "Total Records")
                    )
             ),
             column(3,
                    div(class = "metric-box",
                        div(class = "metric-number", textOutput("avg_rating")),
                        div(class = "metric-label", "Avg Rating")
                    )
             ),
             column(3,
                    div(class = "metric-box",
                        div(class = "metric-number", textOutput("total_partners")),
                        div(class = "metric-label", "Partner Categories")
                    )
             ),
             column(3,
                    div(class = "metric-box",
                        div(class = "metric-number", textOutput("connection_status")),
                        div(class = "metric-label", "DB Status")
                    )
             )
           )
    )
  ),
  
  br(),
  
  # Tabs
  tabsetPanel(
    # Data Tab
    tabPanel("📋 Data",
             br(),
             fluidRow(
               column(12,
                      h4("Data Konsumen"),
                      DT::dataTableOutput("data_table")
               )
             )
    ),
    
    # Charts Tab
    tabPanel("📈 Grafik",
             br(),
             fluidRow(
               column(6,
                      h4("Status Konsumen"),
                      plotOutput("status_chart")
               ),
               column(6,
                      h4("Kategori Partner"),
                      plotOutput("partner_chart")
               )
             ),
             br(),
             fluidRow(
               column(6,
                      h4("Tipe Kendaraan"),
                      plotOutput("vehicle_chart")
               ),
               column(6,
                      h4("Metode Pembayaran"),
                      plotOutput("payment_chart")
               )
             )
    ),
    
    # Raw Query Tab
    tabPanel("🔍 Query",
             br(),
             fluidRow(
               column(12,
                      h4("Custom Query"),
                      textAreaInput("custom_query", 
                                    "SQL Query:", 
                                    value = "SELECT * FROM data_gabungan_rating_konsumer LIMIT 10;",
                                    rows = 4, 
                                    width = "100%"),
                      actionButton("run_query", "Run Query", class = "btn-primary"),
                      br(), br(),
                      DT::dataTableOutput("query_result")
               )
             )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Load data
  konsumen_data <- reactive({
    get_data()
  })
  
  # Metrics
  output$total_records <- renderText({
    data <- konsumen_data()
    if ("Error" %in% names(data)) {
      "Error"
    } else {
      format(nrow(data), big.mark = ",")
    }
  })
  
  output$avg_rating <- renderText({
    data <- konsumen_data()
    if ("Error" %in% names(data) || !"avg_rating" %in% names(data)) {
      "N/A"
    } else {
      round(mean(data$avg_rating, na.rm = TRUE), 1)
    }
  })
  
  output$total_partners <- renderText({
    data <- konsumen_data()
    if ("Error" %in% names(data) || !"kategori_partner" %in% names(data)) {
      "N/A"
    } else {
      length(unique(data$kategori_partner))
    }
  })
  
  output$connection_status <- renderText({
    data <- konsumen_data()
    if ("Error" %in% names(data)) {
      "❌ Failed"
    } else {
      "✅ Connected"
    }
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    data <- konsumen_data()
    if ("Error" %in% names(data)) {
      data.frame(Message = "Failed to load data. Please check database connection.")
    } else {
      data
    }
  }, options = list(
    scrollX = TRUE,
    pageLength = 10,
    lengthMenu = c(10, 25, 50, 100)
  ))
  
  # Status chart
  output$status_chart <- renderPlot({
    data <- konsumen_data()
    if (!"Error" %in% names(data) && "status" %in% names(data)) {
      status_count <- data %>% 
        count(status) %>%
        arrange(desc(n))
      
      ggplot(status_count, aes(x = reorder(status, n), y = n)) +
        geom_col(fill = "steelblue", alpha = 0.8) +
        coord_flip() +
        labs(x = "Status", y = "Count") +
        theme_minimal() +
        theme(axis.text = element_text(size = 10))
    }
  })
  
  # Partner chart
  output$partner_chart <- renderPlot({
    data <- konsumen_data()
    if (!"Error" %in% names(data) && "kategori_partner" %in% names(data)) {
      partner_count <- data %>% 
        count(kategori_partner) %>%
        arrange(desc(n)) %>%
        head(10)
      
      ggplot(partner_count, aes(x = reorder(kategori_partner, n), y = n)) +
        geom_col(fill = "darkgreen", alpha = 0.8) +
        coord_flip() +
        labs(x = "Kategori Partner", y = "Count") +
        theme_minimal() +
        theme(axis.text = element_text(size = 10))
    }
  })
  
  # Vehicle chart
  output$vehicle_chart <- renderPlot({
    data <- konsumen_data()
    if (!"Error" %in% names(data) && "kendaraan" %in% names(data)) {
      vehicle_count <- data %>% 
        count(kendaraan) %>%
        arrange(desc(n))
      
      ggplot(vehicle_count, aes(x = reorder(kendaraan, n), y = n)) +
        geom_col(fill = "orange", alpha = 0.8) +
        coord_flip() +
        labs(x = "Kendaraan", y = "Count") +
        theme_minimal() +
        theme(axis.text = element_text(size = 10))
    }
  })
  
  # Payment chart
  output$payment_chart <- renderPlot({
    data <- konsumen_data()
    if (!"Error" %in% names(data) && "kategori_bb" %in% names(data)) {
      payment_count <- data %>% 
        count(kategori_bb) %>%
        arrange(desc(n))
      
      ggplot(payment_count, aes(x = reorder(kategori_bb, n), y = n)) +
        geom_col(fill = "purple", alpha = 0.8) +
        coord_flip() +
        labs(x = "Kategori BB", y = "Count") +
        theme_minimal() +
        theme(axis.text = element_text(size = 10))
    }
  })
  
  # Custom query
  observeEvent(input$run_query, {
    output$query_result <- DT::renderDataTable({
      tryCatch({
        # Connect to database
        conn <- dbConnect(
          PostgreSQL(),
          host = "yamanote.proxy.rlwy.net",
          port = 58101,
          dbname = "railway",
          user = "postgres",
          password = "qbOqtrqNgcbMMhDmvHJbXdfKRfgZDxdk"
        )
        
        # Run query
        result <- dbGetQuery(conn, input$custom_query)
        
        # Close connection
        dbDisconnect(conn)
        
        result
      }, error = function(e) {
        data.frame(Error = paste("Query failed:", e$message))
      })
    }, options = list(scrollX = TRUE, pageLength = 10))
  })
}

# Run the app
shinyApp(ui = ui, server = server)