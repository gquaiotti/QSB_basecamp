USE [basecamp]
GO
/****** Object:  Table [dbo].[calendar_t]    Script Date: 14/08/2019 17:51:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[calendar_t](
	[id] [int] NOT NULL,
	[name] [varchar](255) NOT NULL,
 CONSTRAINT [calendar_pk] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
