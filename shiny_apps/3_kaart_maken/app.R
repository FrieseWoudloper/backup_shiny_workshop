#
# Dit is een Shiny web app.
# Je kunt 'm starten door op de Run App knop rechtsboven in dit scherm te klikken.
#

# Libraries
library(tidyverse)
library(leaflet)
library(shiny)
library(shinydashboard)
library(RColorBrewer)
library(jsonlite)

# Data 
bevingen <- read_csv("../../data/bevingen.csv") 
veld <- read_json("../../data/groningenveld.json")
brtAchtergrondkaart <- "http://geodata.nationaalgeoregister.nl/tiles/service/wmts/brtachtergrondkaartgrijs/EPSG:3857/{z}/{x}/{y}.png"

# Kleurenpalet
pal <- colorNumeric(palette = "YlOrRd", domain = c(-1:4))

# Gebruikersinterface
header <- dashboardHeader(title = "Kaart")

sidebar <- dashboardSidebar(disable = TRUE)

body <- dashboardBody(
  box(width = 6, leafletOutput(outputId = "kaart", height = 600)),
  box(
    width = 2, 
    numericInput(inputId = "drempelwaarde", label = "Drempelwaarde", min = -1, max = 4, step = 0.1, value = -1),
    checkboxInput(inputId = "groningenVeld", label = "Groningen veld tonen", value = FALSE)
  )
)

ui <- dashboardPage(header, sidebar, body)

# Server
server <- function(input, output) {
  # Filter data op basis van drempelwaarde
  gefilterdeBevingen <- reactive({
                          bevingen %>% 
                            filter(magnitude >= input$drempelwaarde)
                        })
  
  # Render kaart
  output$kaart <- renderLeaflet({
    leaflet() %>%
      addTiles(urlTemplate = brtAchtergrondkaart,
               attribution = "Kaartgegevens &copy; Kadaster",
               options = tileOptions(minZoom = 6, maxZoom = 18)) %>%
      addMapPane("groningen veld",  zIndex = 410) %>%
      addMapPane("bevingen",  zIndex = 420) %>%
      addTopoJSON(topojson = veld, weight = 1, color = "#555555", opacity = 1, fillOpacity = 0.3,
                  options = pathOptions(pane = "groningen veld"), group = "groningen veld") %>%
      setView(6.8, 53.3, zoom = 10) %>%
      hideGroup("groningen veld")
  })
  
  # Toon alleen gefilterde punten op de kaart
  observe({
    leafletProxy(mapId = "kaart") %>%
      clearShapes() %>%
      addCircles(data = gefilterdeBevingen(), lng = ~longitude, lat = ~latitude, color = ~pal(magnitude),
                 weight = 1, radius = ~10^magnitude/10, fillOpacity = 0.7,
                 popup = ~paste("Datum: ", format(datum, "%d-%m-%Y"), "<br>",
                                "Locatie:", locatie, "<br>",
                                "Magnitude:" , magnitude),
                 options = pathOptions(pane = "bevingen")) 
  })  
  
  # Zet de kaartlaag met het gasveld aan of uit afhankelijk van de waarde van de checkbox
  observe({
    if (input$groningenVeld) {
      leafletProxy(mapId = "kaart") %>% showGroup("groningen veld")
    } else {
      leafletProxy(mapId = "kaart") %>% hideGroup("groningen veld")
    }  
  })
}

# Start de app
shinyApp(ui, server)