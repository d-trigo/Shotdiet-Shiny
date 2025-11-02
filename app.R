library(tidyverse)
library(hoopR)
library(shiny)
library(duckdb)
library(DBI)
library(gt)


ui <- fluidPage(
  sidebarPanel(
    selectInput("year", "Year:",
                c("2025-26" = 2026,
                  "2024-25" = 2025,
                  "2023-24" = 2024,
                  "2022-23" = 2023,
                  "2021-22" = 2022))
  ),
  sidebarPanel(
    selectInput("shottype", "Shot Type:",
                c("Drives" = '%driving%',
                  "Floaters" = '%float%',
                  "Hooks" = '%hook%',
                  "Layups" = '%layup%',
                  "Pullups" = '%pull-up%',
                  "Stepbacks" = '%step back%'))
  ),
  
  
  gt_output(outputId = "table") #output table
)

server <- function(input, output, session) {
  

  #note: with the PBP data, we don't have the athlete names as a separate column by default. this will require some regex work. hopefully i find a way to grab ESPN IDs in the future so we skip regex
  
  output$table <- 
    render_gt({
      con <- dbConnect(duckdb())
      
      load_nba_pbp(seasons = as.numeric(input$year), dbConnection = con, tablename = "pbp")
      
      query <- 
        "SELECT 
          
            CASE WHEN text ILIKE '%blocks%' AND shooting_play = TRUE 
              THEN regexp_extract(text, 'blocks\\s+([^;]*)''s', 1)
              
            WHEN text NOT ILIKE '%blocks%' AND shooting_play = TRUE
             THEN regexp_extract(text, '^(.+?)(?:makes|misses)', 1)
              
            WHEN shooting_play = FALSE
              THEN 'NON-SHOOTING PLAY'
              
            END AS player_name,
            
          SUM(CASE WHEN type_text ILIKE ?shottype THEN 1 ELSE 0 END) AS ShotType_Attempts,
          
          SUM(CASE WHEN shooting_play = 'TRUE' THEN 1 ELSE 0 END) AS Total_FGA,
          
          SUM(CASE WHEN type_text ILIKE ?shottype THEN 1 ELSE 0 END)/sum(CASE WHEN shooting_play = 'TRUE' THEN 1 ELSE 0 END) AS ShotType_Proportion,
          
          SUM(CASE WHEN type_text ILIKE ?shottype AND scoring_play = 'TRUE' THEN 1 ELSE 0 END)/sum(CASE WHEN type_text ILIKE ?shottype THEN 1 ELSE 0 END) AS ShotType_Efficiency
          
          
          
          FROM pbp
          GROUP BY player_name
          ORDER BY ShotType_Attempts DESC"
      
      query <- sqlInterpolate(conn = con, sql = query, shottype = input$shottype)
      shottype_table <- dbGetQuery(con, query)
      shottype_table|>
        dplyr::filter(player_name!="NON-SHOOTING PLAY")|>
        dplyr::mutate(ShotType_Proportion = round(ShotType_Proportion, 2))|>
        dplyr::mutate(ShotType_Efficiency = round(ShotType_Efficiency, 2))|>
        gt()|>
        opt_interactive()
    })
}


shinyApp(ui = ui, server = server)