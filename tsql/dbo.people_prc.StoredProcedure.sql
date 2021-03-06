USE [basecamp]
GO
/****** Object:  StoredProcedure [dbo].[people_prc]    Script Date: 14/08/2019 17:51:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Gabriel Quaiotti
-- Create date: Agosto 2019
-- Description:	Preenche o codigo da matricula na tabela people_t
-- atraves do e-mail cadastrado no basecamp e no sistema de apontamento
-- =============================================
CREATE PROCEDURE [dbo].[people_prc]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE people_t
	   SET c_matricula = (SELECT MAX(QAA.QAA_MAT)
	                        FROM QAA
						   WHERE RTRIM(LTRIM(LOWER(QAA.QAA_EMAIL))) = RTRIM(LTRIM(LOWER(email_address))))
END
GO
