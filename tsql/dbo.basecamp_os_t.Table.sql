USE [basecamp]
GO
/****** Object:  Table [dbo].[basecamp_os_t]    Script Date: 14/08/2019 17:51:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[basecamp_os_t](
	[d_data] [date] NULL,
	[n_ano] [int] NULL,
	[n_mes] [int] NULL,
	[n_dia] [int] NULL,
	[n_dia_da_semana] [int] NULL,
	[n_semana] [int] NULL,
	[c_matricula] [varchar](6) NULL,
	[c_basecamp_nome] [varchar](255) NULL,
	[c_os_nome] [varchar](255) NULL,
	[c_basecamp_cliente] [varchar](255) NULL,
	[c_os_cliente] [varchar](255) NULL,
	[c_basecamp_coordenador] [varchar](6) NULL,
	[c_basecamp_coord_nome] [varchar](255) NULL,
	[c_os_coordenador] [varchar](6) NULL,
	[c_os_coordenador_nome] [varchar](255) NULL,
	[c_os_numero] [varchar](6) NULL,
	[n_os_horas] [float] NULL
) ON [PRIMARY]
GO
