#' ---
#' title: "QSdoBrasil - Integracao Basecamp"
#' author: "Gabriel Quaiotti"
#' date: "2019-08-09"
#' ---

# Replica eventos de feriado no calendario QSDOBRASIL BI 
# para todos os calendarios e projetos

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

df <- sqlQuery(channel = dbconnection, query = "SELECT calendar_id, project_id,summary,description,starts_at,ends_at FROM dbo.create_holiday_event_f();")

# Fecha a conexao
odbcClose(dbconnection)

if (nrow(df) > 0) {
  df$all_day <- TRUE
  df$starts_at <- paste(df$starts_at, "T00:00:00-03:00", sep = "")
}

# Somente eventos de projeto
df1 <- df %>% filter(! is.na(project_id))

for (i in seq(1, nrow(df1))) {
  
  # end point
  url <- paste("https://basecamp.com/", basecamp_userid,"/api/v1/projects/", df1[i, "project_id"] , "/calendar_events.json", sep = "")
  
  # chamada para a API do basecamp
  resp <- httr::POST(url = url,
                     config = authenticate(basecamp_user, basecamp_pass, type = "basic"),
                     add_headers("User-Agent: gabriel.quaiotti@qsdobrasil.com"),
                     add_headers("Host: basecamp.com"),
                     add_headers("Content-Type: application/json"),
                     add_headers("Cache-Control: no-cache"),
                     #body = json,
                     body=list(summary = df1[i, "summary"],
                               description = df1[i, "description"],
                               starts_at = df1[i, "starts_at"],
                               ends_at = df1[i, "ends_at"],
                               all_day = df1[i, "all_day"]),
                     encode = "json")
  
  
  
}

# Somente eventos de calendario
df1 <- df %>% filter(! is.na(calendar_id))

for (i in seq(1, nrow(df1))) {
  
  # end point
  url <- paste("https://basecamp.com/", basecamp_userid,"/api/v1/calendars/", df1[i, "calendar_id"] , "/calendar_events.json", sep = "")
  
  # chamada para a API do basecamp
  resp <- httr::POST(url = url,
                     config = authenticate(basecamp_user, basecamp_pass, type = "basic"),
                     add_headers("User-Agent: gabriel.quaiotti@qsdobrasil.com"),
                     add_headers("Host: basecamp.com"),
                     add_headers("Content-Type: application/json"),
                     add_headers("Cache-Control: no-cache"),
                     #body = json,
                     body=list(summary = df1[i, "summary"],
                               description = df1[i, "description"],
                               starts_at = df1[i, "starts_at"],
                               ends_at = df1[i, "ends_at"],
                               all_day = df1[i, "all_day"]),
                     encode = "json")
  
  
  
}