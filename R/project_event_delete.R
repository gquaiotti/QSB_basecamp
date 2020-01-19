#' ---
#' title: "QSdoBrasil - Integracao Basecamp"
#' author: "Gabriel Quaiotti"
#' date: "2019-08-09"
#' ---

# Exclui eventos de projeto criados pela interface automaticamente mas que nao 
# existem mais como evento de calendario
#

setwd("D:/basecamp/R")

library(httr)
library(jsonlite)
library(RODBC)
library(dplyr)
library(stringr)
library(ini)

# configuracao
ini <- ini::read.ini(filepath = here("src/basecamp.ini"))

# parametros da conexao ao basecamp
basecamp_user <- ini$basecamp_user
basecamp_pass <- ini$basecamp_pass
basecamp_userid <- ini$basecamp_userid
basecamp_header <- ini$basecamp_header

sql_server_connection <- paste("driver={SQL Server Native Client 11.0};server=",ini$sql_server,";database=",ini$sql_database,";Uid=; Pwd=; trusted_connection=yes", sep = "")

# Conexao ao SQL Server
dbconnection <- odbcDriverConnect(sql_server_connection)

df <- sqlQuery(channel = dbconnection, query = "SELECT project_id, project_event_id FROM dbo.delete_project_event_f()")

for (i in seq(1, nrow(df))) {
  
  # end point
  url <- paste("https://basecamp.com/", basecamp_userid,"/api/v1/projects/", df[i, "project_id"] , "/calendar_events/", df[i, "project_event_id"] ,".json", sep = "")
  
  # chamada para a API do basecamp
  resp <- httr::DELETE(url = url,
                       config = authenticate(basecamp_user, basecamp_pass, type = "basic"),
                       add_headers("User-Agent: gabriel.quaiotti@qsdobrasil.com"),
                       add_headers("Host: basecamp.com"),
                       add_headers("Content-Type: application/json"),
                       add_headers("Cache-Control: no-cache"),
                       encode = "json")
  
  
  
}

# Fecha a conexao
odbcClose(dbconnection)