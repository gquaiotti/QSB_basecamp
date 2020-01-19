#' ---
#' title: "QSdoBrasil - Integracao Basecamp"
#' author: "Gabriel Quaiotti"
#' date: "2019-08-09"
#' ---

#
# Extrai as informacoes de CALENDARIO do basecamp e carrega a tabele calendar_t no SQL Server
#

setwd("D:/basecamp/R")

# install.packages("httr")
# install.packages("jsonlite")
# install.packages("RODBC")
# install.packages("dplyr")
# install.packages("stringr")
# install.packages("lubridate")

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

basecamp_endpoint <- "calendars.json"

sql_server_connection <- paste("driver={SQL Server Native Client 11.0};server=",ini$sql_server,";database=",ini$sql_database,";Uid=; Pwd=; trusted_connection=yes", sep = "")


# tabela destino no SQL Server
sql_table <- "calendar_t"

# end point
url <- paste("https://basecamp.com/", basecamp_userid,"/api/v1/", basecamp_endpoint, sep = "")

# chamada para a API do basecamp
basecamp_json <- httr::GET(url = url, 
                           config = authenticate(basecamp_user, basecamp_pass, type = "basic"),
                           add_headers("User-Agent: MyApp (gabriel.quaiotti@qsdobrasil.com)"))

# transforma o retorno para data.frame
df <- jsonlite::fromJSON(txt = content(basecamp_json, as = "text"))

# tratamento dos dados extraidos do basecamp
df <- select(.data = df, id, name) %>% 
  mutate(name = str_to_upper(str_replace(str_replace(name, "\\.", ""), "\\,","")))

# Conexao ao SQL Server
dbconnection <- odbcDriverConnect(sql_server_connection)

# Limpa a tabela no SQL Server
sqlQuery(channel = dbconnection, paste("set nocount on;", "delete", sql_table))

# Carrega a tabela 
sqlSave(channel = dbconnection, dat = df, tablename = sql_table, append = TRUE, colnames = FALSE, rownames = FALSE)

# Fecha a conexao
odbcClose(dbconnection)