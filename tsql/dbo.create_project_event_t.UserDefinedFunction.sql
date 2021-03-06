USE [basecamp]
GO
/****** Object:  UserDefinedFunction [dbo].[create_project_event_t]    Script Date: 14/08/2019 17:51:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Gabriel Quaiotti
-- Create date: Agosto 2019
-- Description:	Cria no basecamp eventos de projeto de acordo com eventos de calendario
-- =============================================
CREATE FUNCTION [dbo].[create_project_event_t]()
RETURNS 
@t_project_event TABLE 
(
	project_id INT,
	summary VARCHAR(255),
	starts_at DATE
)
AS
BEGIN
	-- Fill the table variable with the rows for your result set
    DECLARE @c_calendar_name VARCHAR(255)
	DECLARE @d_date DATE
	DECLARE @c_summary VARCHAR(255)

	DECLARE @n_project_id INT
	DECLARE @n_project_match INT
	DECLARE @n_event_match INT

	-- loop para cada evento de calendario (calendario == analista)
	DECLARE c_calendar
	 CURSOR FOR 
	 select c.name as calendar_name,
		   e.date,
		   e.summary
	  from calendar_t c
	  join calendar_event_date_t e
		on e.calendar_id = c.id

	 WHERE c.name = 'Gabriel Quaiotti'
	   AND e.date >= GETDATE()
	   AND e.summary like '%COLOMBO%'

	 order by calendar_name, date

	OPEN c_calendar

	FETCH NEXT
	 FROM c_calendar
	 INTO @c_calendar_name, @d_date, @c_summary

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
	  -- tenta localizar um projeto condizente atraves do nome
	  SELECT @n_project_match = COUNT(1)
	    FROM project_t p
	   WHERE (p.name LIKE '%' + @c_summary + '%' OR @c_summary LIKE '%' + p.name + '%')

	  -- Se encontrar somente uma correspondencia, prossegue
	  IF @n_project_match = 1
	  BEGIN
	    -- busca o id do projeto
		SELECT @n_project_id = p.id
		  FROM  project_t p
		 WHERE (p.name LIKE '%' + @c_summary + '%' OR @c_summary LIKE '%' + p.name + '%')

		-- Verifica se ja existe evento similar criado para o analista neste projeto
		SELECT @n_event_match = COUNT(1)
		  FROM project_event_date_t e
		 WHERE e.project_id = @n_project_id
		   AND e.date = @d_date
		   AND (e.summary LIKE '%' + @c_calendar_name + '%' OR @c_calendar_name LIKE '%' + e.summary + '%')

		-- Se nao houver evento, cria novo evento
		IF ISNULL(@n_event_match, 0) = 0
		BEGIN
		  INSERT INTO @t_project_event (project_id, starts_at, summary)
		  VALUES (@n_project_id, @d_date, @c_calendar_name)
		END
	  
	  END

      FETCH NEXT
	   FROM c_calendar
	   INTO @c_calendar_name, @d_date, @c_summary
	END

	CLOSE c_calendar
	DEALLOCATE c_calendar
	
	RETURN 
END
GO
