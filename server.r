##### stworzenie serwera aplikacji shiny

shinyServer(function(input, output, session) {
  
  
  output$strefy.zwierzeta <- renderDataTable(
    load.strefy.zwierzeta(input$Strefy),
    options = list(
      pageLength = 100,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  output$gatunki.zwierzeta <- renderDataTable(
    load.gatunki.zwierzeta(input$gatunki),
    options = list(
      pageLength = 100,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  observeEvent(input$usun_zwierze,
                 if(length(input$zwierze.imie) == 1){
                     remove.zwierze(input$zwierze.imie)
                     showNotification("Usunieto zwierze z bazy")
                   }
                 else
                   showNotification("Nie ma takiego zwierzecia")
               
  )
  
  observeEvent(input$dodaj_zwierze,
               if(length(input$zwierze.imie2) == 1 ){
                 if(input$zwierze.plec=='K' | input$zwierze.plec=='M' | input$zwierze.plec=='')
                 {
                   add.zwierze(input$zwierze.imie2,input$zwierze.gatunki, input$zwierze.data_urodzenia, input$zwierze.plec)
                   showNotification("Dodano zwierze do bazy")
                 }
                 else showNotification("Proszę podać poprawną płeć (k/m)")
                 
               }
               else showNotification("Nie można dodać do bazy")
               
  )
            
  
  output$lecznica <- renderDataTable(
    load.lecznica(),
    options = list(
      pageLength = 100,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  output$lecznica.historia_choroby <- renderDataTable(
    load.lecznica.historia_choroby(input$lecznica.imie),
    options = list(
      pageLength = 100,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  observeEvent(input$wypisz_zwierze,
               if(TRUE){
                 remove.zwierze_z_lecznicy(input$lecznica.imie3,input$lecznica.data_wypisania)
                 showNotification("Wypisano zwierzę z lecznicy")
               }
  )
  
  
  observeEvent(input$dodaj_wpis,
               if(TRUE){
                   add.wpis(input$lecznica.imie2,input$lecznica.data_wpisania, input$lecznica.uwagi)
                   showNotification("Przeniesiono zwierzę do lecznicy")
               }
  )

  output$zatrudnieni <- renderDataTable(
    load.zatrudnieni(),
    options = list(
      pageLength = 100,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  observeEvent(input$zatrudnij,
               if(TRUE){
                 add.pracownik(input$pracownicy.imie,input$pracownicy.nazwisko, input$pracownicy.stanowisko, input$pracownicy.strefa)
                 showNotification("Dodano nowego pracownika")
               }
  )
  
  
  observeEvent(input$zwolnij,
               if(TRUE){
                 remove.pracownik(input$pracownicy.id)
                 showNotification("Usunięto pracownika z bazy")
               }
  )
  
  
  output$historia <- renderDataTable(
    load.historia(input$finanse.data_pocz, input$finanse.data_kon),
    options = list(
      pageLength = 100,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  output$zysk <- renderDataTable( 
    avg.zysk(input$finanse.data_pocz, input$finanse.data_kon),
    options = list(
      pageLength = 100,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
  )
  )
}
)
