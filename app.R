library(tidyverse)
library(hoopR)
library(shiny)
library(gt)
library(gtExtras)
library(gtUtils)
library(paletteer)
library(magick)

fetchPBP <- function(season){
  pbp_df <- load_nba_pbp(seasons = as.numeric(season))
  pbp_df <- pbp_df|>
    mutate(player_name = case_when(
      str_detect(text, "blocks") & shooting_play == TRUE ~ str_extract(text, "blocks\\s+([^;]*)''s", group = 1),
      !str_detect(text, "blocks") & shooting_play == TRUE ~ str_extract(text, "^(.+?)(?:makes|misses)", group = 1),
      .default = NA
    ))
  return(pbp_df)
}

table_transformation <- function(df, shottype){
  df <- df|>
    filter(!is.na(player_name))|>
    summarize(
      .by = player_name,
      ShotType_Attempts = sum(str_detect(type_text, regex({{shottype}}, ignore_case = TRUE)) == TRUE)/length(unique(game_id)),
      ShotType_Made = sum(str_detect(type_text, regex({{shottype}}, ignore_case = TRUE)) == TRUE & scoring_play == TRUE)/length(unique(game_id)),
      Games_Played = length(unique(game_id)),
      ShotType_Totals = sum(str_detect(type_text, regex({{shottype}}, ignore_case = TRUE))),
      Total_FGA = sum(shooting_play==TRUE),
      ShotType_Proportion = sum(str_detect(type_text, regex({{shottype}}, ignore_case = TRUE)) & shooting_play == TRUE)/sum(shooting_play==TRUE),
      ShotType_Efficiency = sum(str_detect(type_text, regex({{shottype}}, ignore_case = TRUE)) & scoring_play ==TRUE)/sum(str_detect(type_text, regex({{shottype}}, ignore_case = TRUE)))
      )
  return(df)
}


ui <- fluidPage(
  sidebarPanel(
    selectInput("year", "Year:",
                c("2025-26" = 2026,
                  "2024-25" = 2025,
                  "2023-24" = 2024,
                  "2022-23" = 2023,
                  "2021-22" = 2022)),
    width = 3
  ),
  sidebarPanel(
    selectInput("shottype", "Shot Type:",
                c("Standing Jump Shot" = 'Jump Shot',
                  "Drives" = 'driving',
                  "Floaters" = 'float',
                  "Hooks" = 'hook',
                  "Layups" = 'layup',
                  "Pullups" = 'pullup',
                  "Stepbacks" = 'step back',
                  "Fadeaways" = 'Fade Away',
                  "Dunks" = 'dunk',
                  "Cuts" = 'cutting')),
    width = 3
  ),
  
  
  gt_output(outputId = "table") #output table
)

server <- function(input, output, session) {
  
  shottype_data <- reactive({
    pbp_data <- fetchPBP(season = input$year)
    return(pbp_data)
  })|>
    bindCache(input$year)
  

  #note: with the PBP data, we don't have the athlete names as a separate column by default. this will require some regex work. hopefully i find a way to grab ESPN IDs in the future so we skip regex
  output$table <- 
    render_gt({
      shot_table <- shottype_data()
      shot_table <- table_transformation(shot_table, input$shottype)
      shot_table|> #note to self: figure out error with Jimmy being changed to Jimmy Butler III. remove roman numerals? 
        arrange(desc(ShotType_Totals))|>
        slice(1:200)|>
        dplyr::mutate(ShotType_Attempts = round(ShotType_Attempts, 2))|>
        dplyr::mutate(ShotType_Made = round(ShotType_Made, 2))|>
        dplyr::mutate(ShotType_Totals = round(ShotType_Totals, 2))|>
        dplyr::mutate(ShotType_Proportion = round(ShotType_Proportion, 2))|>
        dplyr::mutate(ShotType_Efficiency = round(ShotType_Efficiency, 2))|>
        gt()|>
        gt_theme_athletic()|>
        cols_label(
          player_name = "Player",
          ShotType_Attempts = "Shot Type FGA (per game)",
          ShotType_Made = "Shot Type FGM (per game)",
          Games_Played = "Games Played",
          Total_FGA = "Total FGA (season)",
          ShotType_Totals = "Shot Type FGA (totals)",
          ShotType_Proportion = "Shot Type Atmpt%",
          ShotType_Efficiency = "Shot Type FG%"
        )|>
        data_color(
          columns = ShotType_Efficiency,
          palette = paletteer_d("rcartocolor::Temps"),
          domain = c(0.00, 1.00),
          reverse = T,
          na_color = '#8FA3ABFF',
          alpha = .75
        )|>
        data_color(
          columns = ShotType_Proportion,
          palette = paletteer_d("beyonce::X47"),
          reverse = T,
          na_color = '#AD8875FF',
          alpha = .75
        )|>
        opt_interactive()
    })
}


shinyApp(ui = ui, server = server)