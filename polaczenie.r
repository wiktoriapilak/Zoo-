library("RPostgres")

##### połączenie z bazą danych
open.my.connection <- function() {
  con <- dbConnect(RPostgres::Postgres(),dbname = 'zoo', 
                   host = 'localhost',
                   port = 5432, # port ten sam co w psql 
                   user = 'postgres',
                   password = 'admin')
  return (con)
}

close.my.connection <- function(con) {
  dbDisconnect(con)
}


##### funkcje pomocnicze
load.strefy <- function() {
  query = "SELECT nazwa_strefy FROM strefy ORDER BY nazwa_strefy ASC"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  strefy = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(strefy)
}

load.imie <- function(imie) {
  query =paste0("SELECT imie FROM zwierzeta WHERE imie='",imie,"'")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  imie = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(imie)
}

load.strefy.zwierzeta <- function(strefa_arg) {
  query = paste0 ("SELECT * from zdrowe_zwierzeta WHERE strefa='", strefa_arg,"'")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  zwierzeta = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(zwierzeta)
}

load.gatunki.zwierzeta <- function(gatunek_arg) {
  query = paste0 ("SELECT * from zdrowe_zwierzeta WHERE gatunek='", gatunek_arg,"'")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  zwierzeta = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(zwierzeta)
}

remove.zwierze <- function(imie) {
  query = paste0("SELECT usun_zwierze('",imie,"')")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

load.gatunki <- function() {
  query = "SELECT nazwa_gatunku FROM niezapelnione_gatunki ORDER BY nazwa_gatunku ASC"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  gatunki = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(gatunki)
}
  
add.zwierze <- function(imie,gatunek,data_urodzenia, plec) {
  query = paste0("SELECT dodaj_zwierze('",imie,"','",gatunek,"','",data_urodzenia,"','",plec,"')")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

load.lecznica <-  function() {
  query = "SELECT * FROM w_lecznicy ORDER BY imie ASC"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  lecznica = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(lecznica)
}

load.lecznica.historia_choroby <-function(imie) {
  query = paste0("SELECT * FROM historia_choroby WHERE imie='",imie,"' ")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  historia_choroby = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(historia_choroby)
}

load.zdrowe <- function() {
  query = "SELECT imie FROM zdrowe_zwierzeta ORDER BY imie ASC"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  zdrowe = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(zdrowe)
}

load.chore <- function() {
  query = "SELECT imie FROM w_lecznicy ORDER BY imie ASC"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  chore = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(chore)
}

add.wpis <- function(imie,data_wpisania, uwagi) {
  query = paste0("SELECT przenies_do_lecznicy('",imie,"','",data_wpisania,"','",uwagi,"')")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

remove.zwierze_z_lecznicy <- function(imie,data_wypisania) {
  query = paste0("SELECT wypisz_zwierze('",imie,"','",data_wypisania,"')")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

load.zatrudnieni <- function() {
  query = "SELECT * FROM zatrudnieni"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  zatrudnieni = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(zatrudnieni)
}

load.stanowiska <- function() {
  query = "SELECT nazwa_stanowiska FROM stanowiska"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  stanowiska = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(stanowiska)
}

add.pracownik <- function(imie,nazwisko, stanowisko, strefa) {
  query = paste0("SELECT zatrudnij_pracownika('",imie,"','",nazwisko,"','",stanowisko,"','",strefa,"','",Sys.Date(),"')")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

remove.pracownik <- function(id) {
  query = paste0("SELECT zwolnij_pracownika('",id,"')")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

load.historia <- function(data_pocz, data_kon) {
  query = paste0("SELECT * FROM historia_biletow WHERE data BETWEEN '",data_pocz,"'AND'",data_kon,"'")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  historia = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(historia)
}

avg.zysk <- function(data_pocz, data_kon) {
  query = paste0("SELECT zysk('",data_pocz,"','",data_kon,"')")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  zysk = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(zysk)
}
