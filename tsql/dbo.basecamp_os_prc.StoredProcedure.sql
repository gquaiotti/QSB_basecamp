USE [basecamp]
GO
/****** Object:  StoredProcedure [dbo].[basecamp_os_prc]    Script Date: 14/08/2019 17:51:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Gabriel Quaiotti
-- Create date: Agosto 2019
-- Description:	Alimenta a tabela basecamp_os_t com o cruzamento dos dados entre basecamp e apontamento de OS
-- =============================================
CREATE PROCEDURE [dbo].[basecamp_os_prc]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @d_data_de DATE
	DECLARE @d_data_ate DATE

	BEGIN TRANSACTION basecamp_os_del
		DELETE basecamp_os_t
	COMMIT TRANSACTION basecamp_os_del

	DECLARE @t_basecamp 
	  TABLE (c_matricula VARCHAR(6),
	         c_nome VARCHAR(255),
			 d_data date,
			 c_cliente varchar(255),
			 c_coordenador varchar(6),
			 c_coordenador_nome varchar(255))
	         
    INSERT INTO @t_basecamp (c_matricula, c_nome, d_data, c_cliente, c_coordenador, c_coordenador_nome)
	SELECT p.c_matricula,
	       p.name as c_nome,
		   e.date,
		   e.summary as c_cliente,
		   b.c_matricula as c_coordenador,
		   b.name as c_coordenador_nome
	  FROM people_t p
	  join calendar_t c
		on c.name = p.name
	  join calendar_event_date_t e
		on e.calendar_id = c.id
	  -- coordenador normalmente eh o criador do evento
	  join people_t b
	    on b.id = e.creator_id

    SELECT @d_data_de = MIN(d_data)
	  FROM @t_basecamp

    SELECT @d_data_ate = MAX(d_data)
	  FROM @t_basecamp

	DECLARE @t_os
	  TABLE (c_matricula VARCHAR(255),
	         c_nome VARCHAR(255),
			 d_data date,
			 c_cliente varchar(255),
			 c_os varchar(255),
			 n_os_horas FLOAT,
			 c_coordenador VARCHAR(6),
			 c_coordenador_nome VARCHAR(255))
    
	INSERT INTO @t_os (c_matricula, c_nome, d_data, c_cliente, c_os, c_coordenador, c_coordenador_nome, n_os_horas)
	SELECT SZC.ZC_MAT AS c_matricula,
	       QAA.QAA_NOME as c_nome,
		   SZC.ZC_DATAOS AS d_data,
		   SA1.A1_NREDUZ AS c_cliente,
		   SZC.ZC_OS AS c_os,
		   SZC.ZC_COORD AS c_coordenador,
		   QAA1.QAA_NOME AS c_coordenador_nome,
		   SZC.ZC_TOTAL AS n_os_horas
      FROM SZC
	  join SA1
        ON SA1.A1_COD = SZC.ZC_CLIENTE
	   AND SA1.A1_LOJA = SZC.ZC_LOJA
	  join QAA
	    ON QAA_MAT = SZC.ZC_MAT
	  JOIN QAA AS QAA1
	    ON QAA1.QAA_MAT = SZC.ZC_COORD
	 where SZC.ZC_DATAOS BETWEEN @d_data_de and @d_data_ate

	-- Casos relacionados
	INSERT INTO [dbo].[basecamp_os_t]
			   ([d_data]
			   ,[n_ano]
			   ,[n_mes]
			   ,[n_dia]
			   ,[n_dia_da_semana]
			   ,[n_semana]
			   ,[c_matricula]
			   ,[c_basecamp_nome]
			   ,[c_os_nome]
			   ,[c_basecamp_cliente]
			   ,[c_os_cliente]
			   ,[c_basecamp_coordenador]
			   ,[c_basecamp_coord_nome]
			   ,[c_os_coordenador]
			   ,[c_os_coordenador_nome]
			   ,[c_os_numero]
			   ,[n_os_horas])
	SELECT b.d_data,
	       YEAR(b.d_data) AS n_ano,
		   MONTH(b.d_data) as n_mes,
		   DAY(b.d_data) AS n_dia,
		   DATEPART(WEEKDAY, b.d_data) AS n_dia_da_semana,
		   DATEPART(WEEK, b.d_data) AS n_semana,
	       b.c_matricula,
		   b.c_nome as c_basecamp_nome, 
           o.c_nome as c_os_nome, 
		   b.c_cliente as c_basecamp_cliente,
		   o.c_cliente as c_os_cliente,
		   b.c_coordenador as c_basecamp_coordenador,
		   b.c_coordenador_nome as c_basecamp_coord_nome,
		   o.c_coordenador as c_os_coordenador,
		   o.c_coordenador_nome as c_os_coordenador_nome,
		   o.c_os as c_os_numero,
		   o.n_os_horas as n_os_horas
	  FROM @t_basecamp b
	  JOIN @t_os o
		ON o.c_matricula = b.c_matricula
	   AND o.d_data = b.d_data
	   AND (b.c_cliente like '%' + o.c_cliente + '%' OR o.c_cliente like '%' + b.c_cliente + '%')

	-- Somente basecamp
	INSERT INTO [dbo].[basecamp_os_t]
			   ([d_data]
			   ,[n_ano]
			   ,[n_mes]
			   ,[n_dia]
			   ,[n_dia_da_semana]
			   ,[n_semana]
			   ,[c_matricula]
			   ,[c_basecamp_nome]
			   ,[c_os_nome]
			   ,[c_basecamp_cliente]
			   ,[c_os_cliente]
			   ,[c_basecamp_coordenador]
			   ,[c_basecamp_coord_nome]
			   ,[c_os_coordenador]
			   ,[c_os_coordenador_nome]
			   ,[c_os_numero]
			   ,[n_os_horas])
	SELECT b.d_data,
	       YEAR(b.d_data) AS n_ano,
		   MONTH(b.d_data) as n_mes,
		   DAY(b.d_data) AS n_dia,
		   DATEPART(WEEKDAY, b.d_data) AS n_dia_da_semana,
		   DATEPART(WEEK, b.d_data) AS n_semana,
	       b.c_matricula,
		   b.c_nome as c_basecamp_nome, 
           NULL as c_os_nome, 
		   b.c_cliente as c_basecamp_cliente,
		   NULL as c_os_cliente,
		   b.c_coordenador as c_basecamp_coordenador,
		   b.c_coordenador_nome as c_basecamp_coord_nome,
		   NULL as c_os_coordenador,
		   NULL as c_os_coordenador_nome,
		   NULL as c_os_numero,
		   NULL as n_os_horas
	  FROM @t_basecamp b
	  WHERE NOT EXISTS (SELECT 1 
	                    FROM @t_os o
	                   WHERE o.c_matricula = b.c_matricula
	                     AND o.d_data = b.d_data
	                     AND (b.c_cliente like '%' + o.c_cliente + '%' OR o.c_cliente like '%' + b.c_cliente + '%'))

	-- Somente apontamento
	INSERT INTO [dbo].[basecamp_os_t]
			   ([d_data]
			   ,[n_ano]
			   ,[n_mes]
			   ,[n_dia]
			   ,[n_dia_da_semana]
			   ,[n_semana]
			   ,[c_matricula]
			   ,[c_basecamp_nome]
			   ,[c_os_nome]
			   ,[c_basecamp_cliente]
			   ,[c_os_cliente]
			   ,[c_basecamp_coordenador]
			   ,[c_basecamp_coord_nome]
			   ,[c_os_coordenador]
			   ,[c_os_coordenador_nome]
			   ,[c_os_numero]
			   ,[n_os_horas])
	SELECT o.d_data,
	       YEAR(o.d_data) AS n_ano,
		   MONTH(o.d_data) as n_mes,
		   DAY(o.d_data) AS n_dia,
		   DATEPART(WEEKDAY, o.d_data) AS n_dia_da_semana,
		   DATEPART(WEEK, o.d_data) AS n_semana,
	       o.c_matricula,
		   NULL as c_basecamp_nome, 
           o.c_nome as c_os_nome, 
		   NULL as c_basecamp_cliente,
		   o.c_cliente as c_os_cliente,
		   NULL as c_basecamp_coordenador,
		   NULL as c_basecamp_coord_nome,
		   o.c_coordenador as c_os_coordenador,
		   o.c_coordenador_nome as c_os_coordenador_nome,
		   o.c_os as c_os_numero,
		   o.n_os_horas as n_os_horas
     FROM @t_os o
	WHERE NOT EXISTS (SELECT 1 
	                    FROM @t_basecamp b
	                   WHERE o.c_matricula = b.c_matricula
	                     AND o.d_data = b.d_data
	                     AND (b.c_cliente like '%' + o.c_cliente + '%' OR o.c_cliente like '%' + b.c_cliente + '%')) 

END
GO
