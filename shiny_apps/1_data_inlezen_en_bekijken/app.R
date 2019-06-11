#
# Dit is een Shiny web app.
# Je kunt 'm starten door op de Run App knop rechtsboven in dit scherm te klikken.
#

# Libraries
library(tidyverse)
library(shiny)
library(shinydashboard)
library(DT)

# Data
bevingen <- read_csv("../../data/bevingen.csv")

# Gebruikersinterface
header <- dashboardHeader(title = "Mijn eerste Shiny app!")

sidebar <- dashboardSidebar(disable = FALSE)

body <- dashboardBody(
          DTOutput(outputId = 'tabel'), 
          downloadButton(outputId = 'downloadData', label = "Download gegevens")
        )

ui <- dashboardPage(header, sidebar, body)

# Server 
server <- function(input, output) {
    dutch <- "http://cdn.datatables.net/plug-ins/1.10.19/i18n/Dutch.json"
    output$tabel <- renderDT(
                      bevingen, 
                      options = list(language = list(url = dutch))
                    )
    
    output$downloadData <- downloadHandler(
                             filename = "bevingen.csv", 
                             content = function(file){write_csv(bevingen, file)}
                           ) 
}

# Start de app
shinyApp(ui, server)