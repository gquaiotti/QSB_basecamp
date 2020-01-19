#' ---
#' title: "QSdoBrasil - Integracao Basecamp"
#' author: "Gabriel Quaiotti"
#' date: "2019-08-09"
#' ---

# Extrai as informacoes de EVENTOS DE CALENDARIO do basecamp e carrega a tabele calendar_t no SQL Server
#

setwd("D:/basecamp/R")

library(httr)
library(jsonlite)
library(RODBC)
library(dplyr)
library(lubridate)
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

api_weeks_per_call <- 6
api_days_per_call <- api_weeks_per_call * 7

# tabela destino no SQL Server
sql_table <- "calendar_event_t"

# Conexao ao SQL Server
dbconnection <- odbcDriverConnect(sql_server_connection)

# Recuperar os calendarios existentes no SQL Server
calendar_t <- sqlQuery(dbconnection, "select id from calendar_t")

# inicializa data.frame
calendar_event_df <- data.frame(matrix(ncol = 9, nrow = 0))
colnames(calendar_event_df) <- c("id", "calendar_id", "starts_at", "ends_at", "summary", "creator_id", "creator_name", "description", "summary_prefix")

# Para cada calendario encontrado
for (calendar_id in calendar_t$id) {
  
  # Define as datas de inicio e fim para capturar os eventos
  # Dois meses atras, dia 20 (inicio de periodo)
  start_date <- Sys.Date() %m-% months(2)
  day(start_date) <- 20
  
  # Doze meses adiante, dia 19 (final de periodo)
  end_date <- Sys.Date() %m+% months(12)
  day(end_date) <- 19
  
  # Busca eventos por semana
  while (start_date < end_date) {
    
    # Tratamento de paginas do retorno no JSON (limite 50 linhas)
    page <- 1
    
    # Enquanto encontrar resultado no JSON
    while (page > 0) {
      
      # end point
      aux_end_date <- start_date + api_days_per_call - 1
      if (aux_end_date > end_date) {
        aux_end_date <- end_date
      }
      
      
      url <- paste("https://basecamp.com/", basecamp_userid,"/api/v1/", "calendars/", calendar_id, "/calendar_events.json?start_date=", start_date, "&end_date=", aux_end_date, "&page=", page, sep = "")
      
      # chamada para a API do basecamp
      basecamp_json <- httr::GET(url = url, 
                                 config = authenticate(basecamp_user, basecamp_pass, type = "basic"),
                                 add_headers("User-Agent: MyApp (gabriel.quaiotti@qsdobrasil.com)"))
      
      # transforma o retorno para data.frame
      df <- jsonlite::fromJSON(txt = content(basecamp_json, as = "text"))
      
      if (!is.null(nrow(df))) {
        # tratamento dos dados extraidos do basecamp
        df$creator_id <- df$creator$id
        df$creator_name <- df$creator$name
        df$summary_prefix <- NA
        
        # tratamento do id
        # esta coluna pode ou nao vir no JSON
        # se vier, mantem o conteudo
        # se nao existir ou for nula busca o id do evento mestre
        if (!("id" %in% colnames(df)))
        {
          df$id <- as.integer(NA)
        }
        
        if ("recurrence" %in% colnames(df)) {
          df$recurrence_master_id <- as.integer(df$recurrence$master$id)
        }
        
        if (!("recurrence" %in% colnames(df))) {
          df$recurrence_master_id <- as.integer(NA)
        }
        
        df <- mutate(.data = df, id = coalesce(id, recurrence_master_id)) %>%
          select(id, summary, starts_at, ends_at, creator_id, creator_name, description, summary_prefix) %>% 
          mutate(calendar_id = calendar_id, starts_at = as.Date(starts_at), ends_at = as.Date(ends_at))
        
        calendar_event_df <- union_all(calendar_event_df, df)
        
        page <- page + 1
      }
      else{
        page <- 0
      }
      
    }
    
    start_date <- start_date + api_days_per_call
  }
  
}

# Limpeza dos dados
calendar_event_df <- distinct(.data = calendar_event_df, id, calendar_id, starts_at, ends_at, summary, creator_id, creator_name, description, summary_prefix) %>%
  mutate(summary = str_to_upper(summary))
# %>%
#   filter(!str_detect(summary, "FERIADO"))

for (i in seq(1, nrow(calendar_event_df))){
  calendar_event_df[i,"summary_prefix"] <- paste(gsub("[\\(\\)]", "", regmatches(calendar_event_df[i,"summary"], gregexpr("\\[.*?\\]", calendar_event_df[i,"summary"]))[[1]]), collapse=" ")
}

# Remove tudo entre parenteses
calendar_event_df$summary <- str_replace(calendar_event_df$summary, "\\(.*\\)", "")
calendar_event_df$summary <- str_replace(calendar_event_df$summary, "\\[.*\\]", "")
calendar_event_df$summary <- str_remove(calendar_event_df$summary, "PR:")
calendar_event_df$summary <- str_remove(calendar_event_df$summary, "PR-")
calendar_event_df$summary <- str_remove(calendar_event_df$summary, "PR - ")
calendar_event_df$summary <- str_remove(calendar_event_df$summary, "RM:")
calendar_event_df$summary <- str_remove(calendar_event_df$summary, "AG:")
calendar_event_df$summary <- str_remove(calendar_event_df$summary, "QS:")
calendar_event_df$summary <- str_remove(calendar_event_df$summary, "QS-")
calendar_event_df$summary <- str_remove(calendar_event_df$summary, "QS - ")
calendar_event_df$summary <- str_trim(calendar_event_df$summary)
calendar_event_df$summary <- calendar_event_df$summary


# Limpa a tabela no SQL Server
sqlQuery(channel = dbconnection, paste("set nocount on;", "delete", sql_table))

# Carrega a tabela 
sqlSave(channel = dbconnection, dat = calendar_event_df, tablename = sql_table, append = TRUE, colnames = FALSE, rownames = FALSE)

# Executa a procedure para carregar a tabela calendar_event_date_t
# separando os eventos onde starts_at < ends_at (varios dias)
sqlQuery(channel = dbconnection, query = "EXEC calendar_event_date_prc;")

# Executa a procedure para carregar a tabela basecamp_os_t
sqlQuery(channel = dbconnection, query = "EXEC basecamp_os_prc;")

# Fecha a conexao
odbcClose(dbconnection)