# install.packages("shiny")
library(shiny)
source(file='polaczenie.r')


##### stworzenie interfejsu graficznego aplikacji shiny
shinyUI(fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background-color:#AACFC5;
        color: black;
        text-align:center;
        margin-left:400px;
  
      }
      
      h1{ 
        color: black;
        font-style: italic;
        font-size: 70px;
        text-align: center;
        
      }
      
      .tabbable > .nav > li > a{
       font-size:30px;
       color:grey;
       background-color:white;
      }
      
      .shiny-input-container {
        color: black;
      }
      
      #usun_zwierze, #dodaj_zwierze, #zatrudnij, #zwolnij,#dodaj_wpis,#wypisz_zwierze, #policz_srednia{
      font-size:15px;
      width:300px;
      color:black;
      }
      
      hr{
        border-top: 1px solid #000000;
      }
      
     "))
  ),
  
  titlePanel(h1("Zoo")),
    mainPanel(
      align="center",
      tabsetPanel(type="pills",
        tabPanel('Zwierzęta',
                hr(),
                fluidRow(
                  column(5,
                    h2("Usuwanie zwierzaka"),
                    textInput(inputId='zwierze.imie', label='Podaj imie'),
                    actionButton(inputId='usun_zwierze', label='Usuń zwierzę')),
                  
                  column(5,
                    h2("Dodawanie zwierzaka"),
                    textInput(inputId='zwierze.imie2', label='Podaj imie'),
                    selectInput(inputId='zwierze.gatunki', label='Wybierz dostępny gatunek',choices=load.gatunki()),
                    dateInput(inputId='zwierze.data_urodzenia', label='Podaj datę urodzenia'),
                    textInput(inputId='zwierze.plec', label='Podaj płeć (M/K)'),
                    actionButton(inputId='dodaj_zwierze',label='Dodaj zwierzę')
                )),
                
                hr(),
                h2("Wyszukaj zwierzaka po:"),
                
                tabsetPanel(type="pills",
                    tabPanel('Strefie',
                        hr(),
                       selectInput(inputId='Strefy',label='Wybierz strefę',choices=load.strefy()),
                       dataTableOutput('strefy.zwierzeta')),
                
                    tabPanel('Gatunku',
                        hr(),
                       selectInput(inputId='gatunki',label='Wybierz gatunek',choices=load.gatunki()),
                       dataTableOutput('gatunki.zwierzeta'))
                ),
        ),
        
        tabPanel('Lecznica',
                 hr(),
                    h2("Wyszukaj historie choroby zwierzęcia"),
                    textInput(inputId='lecznica.imie', label='Podaj imie'),
                    dataTableOutput('lecznica.historia_choroby'),
                 hr(),
                 
                   fluidRow(
                     column(6,
                      h2("Dodaj wpis"),
                      textInput(inputId='lecznica.imie2', label='Wpisz imie'),
                      dateInput(inputId='lecznica.data_wpisania', label='Podaj date wpisania'),
                      textInput(inputId='lecznica.uwagi', label='Wpisz dodatkowe uwagi'),
                      actionButton(inputId='dodaj_wpis', label='Dodaj wpis')
                     ),
                     
                     column(6,
                      h2("Wypisz zwierze z lecznicy"),
                      textInput(inputId='lecznica.imie3',label='Wpisz imie'),
                      dateInput(inputId='lecznica.data_wypisania',label='Data wypisania', min=Sys.Date(), max=Sys.Date()),
                      actionButton(inputId='wypisz_zwierze', label='Wypisz zwierzę',)
                     )),
                 
                   hr(),
                   h2("Zwierzęta w lecznicy"),
                   dataTableOutput('lecznica')
                   
              ),
        
        tabPanel('Finanse',
                 hr(),
                 h2("Policz zysk z podanego okresu"),
                 fluidRow(
                   column(4,
                          br(),
                          dateInput(inputId='finanse.data_pocz', label='OD', value='2022-10-01')
                   ),
                   
                   column(4,
                          br(),
                          dateInput(inputId='finanse.data_kon', label='DO')
                   ),
                   column(4,       
                        dataTableOutput('zysk')
                   )),
                 hr(),
                 dataTableOutput('historia')
                 
              ),
        
        tabPanel('Pracownicy',
                 hr(),
                 fluidRow(
                   column(6,
                          h2("Zatrudnij pracownika"),
                          textInput(inputId='pracownicy.imie', label='Podaj imie'),
                          textInput(inputId='pracownicy.nazwisko', label='Podaj nazwisko'),
                          selectInput(inputId='pracownicy.strefa', label='Wybierz strefe', choices=load.strefy()),
                          selectInput(inputId='pracownicy.stanowisko', label='Wybierz stanowisko', choices=load.stanowiska()),
                          actionButton(inputId='zatrudnij', label='Zatrudnij')
                   ),
                   
                   column(6,
                          h2("Zwolnij pracownika"),
                          textInput(inputId='pracownicy.id',label='Wpisz nr pracownika'),
                          actionButton(inputId='zwolnij', label='Zwolnij')
                   )),
                 hr(),
                 h2("Pracownicy w zoo"),
                 dataTableOutput('zatrudnieni')
                 
              )
   )
  )
)
)


