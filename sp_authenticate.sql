USE [db_prospection]
GO
/****** Object:  StoredProcedure [dbo].[sp_authenticate]    Script Date: 03/08/2012 15:12:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER
PROCEDURE [dbo].[sp_authenticate]
@UserMail varchar(50)  , @Password varchar(50)as 
begin  
if exists (select * from prospecteurs as ps    where ps.mail = @UserMail AND ps.pass = @Password)  
  select 1 as checked;  
else    select 0 as checked;
end