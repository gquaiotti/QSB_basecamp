USE [basecamp]
GO
/****** Object:  Table [dbo].[calendar_event_date_t]    Script Date: 14/08/2019 17:51:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[calendar_event_date_t](
	[calendar_id] [int] NOT NULL,
	[date] [date] NULL,
	[summary] [varchar](255) NOT NULL,
	[creator_id] [int] NULL,
	[creator_name] [varchar](255) NOT NULL
) ON [PRIMARY]
GO
