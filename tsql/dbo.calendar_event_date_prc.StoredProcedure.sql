USE [basecamp]
GO
/****** Object:  StoredProcedure [dbo].[calendar_event_date_prc]    Script Date: 14/08/2019 17:51:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Gabriel Quaiotti
-- Create date: Ago 2019
-- Description:	Carrega a tabela calendar_event_date_t atraves da tabela
-- calendar_event_t separando em varias linhas os casos on de starts_at < ends_at
-- =============================================
CREATE PROCEDURE [dbo].[calendar_event_date_prc]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @calendar_id INT
	DECLARE @starts_at DATE
	DECLARE @ends_at DATE
	DECLARE @summary VARCHAR(255)
	DECLARE @creator_id INT
	DECLARE @creator_name VARCHAR(255)
	DECLARE @date DATE

	BEGIN TRANSACTION calendar_event_date_t_delete
		DELETE calendar_event_date_t
    COMMIT TRANSACTION calendar_event_date_t_delete

	DECLARE c_calendar_event
	 CURSOR FOR 
	 SELECT c.calendar_id,
	        c.starts_at,
			c.ends_at,
			c.summary,
			c.creator_id,
			c.creator_name
	   FROM calendar_event_t c

	OPEN c_calendar_event

	FETCH NEXT
	 FROM c_calendar_event
	 INTO @calendar_id, @starts_at, @ends_at, @summary, @creator_id, @creator_name
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @date = @starts_at

		WHILE (@date <= @ends_at)
		BEGIN
			BEGIN TRANSACTION calendar_event_date_t_insert
				INSERT INTO calendar_event_date_t (calendar_id, date, summary, creator_id, creator_name)
				VALUES (@calendar_id, @date, @summary, @creator_id, @creator_name)
			COMMIT TRANSACTION calendar_event_date_t_insert

			SET @date = DATEADD(DAY, 1, @date)
		END

		FETCH NEXT
		 FROM c_calendar_event
		 INTO @calendar_id, @starts_at, @ends_at, @summary, @creator_id, @creator_name 
	END

    CLOSE c_calendar_event
	DEALLOCATE c_calendar_event
END
GO
