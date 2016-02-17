/*

T-SQL Script: Creating a table with a given contact's primary & secondary email addresses.

Background: *For years, database simply loaded its INDIVIDUAL table and updated INDIVIDUAL.PRIMARY_EMAIL to the most recent email received. 
			*Recently added a table called INDIVIDUAL_EMAIL which looks like 
					CREATE TABLE INDIVIDUAL_EMAIL 
					(	INDIV_ID NUMERIC(10,0)
					   ,EMAIL VARCHAR(75)
					   ,PRIMARY_FLAG CHAR(1)
					   ,INSERT_DATE DATETIME
					   ,UPDATE_DATE DATETIME
					)
			*For INDIV_IDs with PRIMARY_FLAG = 'Y' we are to determine their Primary & Secondary Email Address.
			*When an email is to be purged from an INDIV_ID, the EMAIL = 'DELETE@ME.COM'. Source cannot send blank emails.
			
 
*/
IF EXISTS (select 0 from dbo.sysobjects where id = object_id(N'[dbo].[TEMP_PRIMARY_BASE]') and OBJECTPROPERTY(id,N'IsUserTable') = 1 )
	BEGIN
		drop table dbo.TEMP_PRIMARY_BASE
	END
	
IF EXISTS (select 0 from dbo.sysobjects where id = object_id(N'[dbo].[TEMP_PRIMARY_WORKING]') and OBJECTPROPERTY(id,N'IsUserTable') = 1 )
	BEGIN
		drop table dbo.TEMP_PRIMARY_WORKING
	END
	
IF EXISTS (select 0 from dbo.sysobjects where id = object_id(N'[dbo].[TEMP_PRIMARY_FINAL]') and OBJECTPROPERTY(id,N'IsUserTable') = 1 )
	BEGIN
		drop table dbo.TEMP_PRIMARY_FINAL
	END

select c.*
      ,ROW_NUMBER() over (partition by INDIV_ID order by UPDATE_DATE desc, EMAIL) RN_ORDER --Used downstream to determine next Email Pair in sequence.
into dbo.TEMP_PRIMARY_BASE
from (     
            select   INDIV_ID
                    ,EMAIL
                    ,PRIMARY_FLAG
                    ,UPDATE_DATE
                    ,ROW_NUMBER() over (partition by INDIV_ID, EMAIL order by UPDATE_DATE desc) RN_EM --Row Number to determine most recent record for a given Indiv/Email pair.
            from dbo.CONTACT_EMAIL            
      ) c
where c.RN_EM = 1
 
--If we get a DELETE@ME.COM in, we want to remove all the older emails from the process. 
delete t1
from dbo.TEMP_PRIMARY_BASE t1
     INNER JOIN dbo.TEMP_PRIMARY_BASE t2 on t1.INDIV_ID = t2.INDIV_ID
where t2.EMAIL = 'DELETE@ME.COM'
      and t1.RN_ORDER >= t2.RN_ORDER
       
--We want to only be using Emails that have the PRIMARY_FLAG field used.
select INDIV_ID
      ,MIN(CASE WHEN PRIMARY_FLAG = 'Y' THEN RN_ORDER ELSE NULL END) RN_INDIV_FIRST_PRIMARY
into dbo.TEMP_PRIMARY_WORKING    
from dbo.TEMP_PRIMARY_BASE
group by INDIV_ID
having MIN(CASE WHEN PRIMARY_FLAG = 'Y' THEN RN_ORDER ELSE NULL END) = 'Y'
 
--2 Cases can occur: Either primary email was last email in (join called sc2). Or primary email wasn't most recent in (join called sc1).  
select f.INDIV_ID
      ,p.EMAIL as PRIMARY_EMAIL
      ,COALESCE(sc1.EMAIL,sc2.EMAIL,' ') as SECONDARY_EMAIL
into dbo.TEMP_PRIMARY_FINAL     
from dbo.TEMP_PRIMARY_WORKING f
      INNER JOIN dbo.TEMP_PRIMARY_BASE p on p.INDIV_ID = f.INDIV_ID and p.RN_ORDER = f.RN_INDIV_FIRST_PRIMARY
      LEFT OUTER JOIN dbo.TEMP_PRIMARY_BASE sc1 on f.INDIV_ID = sc1.INDIV_ID and f.RN_INDIV_FIRST_PRIMARY > 1 and sc1.RN_ORDER = 1
      LEFT OUTER JOIN dbo.TEMP_PRIMARY_BASE sc2 on f.INDIV_ID = sc2.INDIV_ID and f.RN_INDIV_FIRST_PRIMARY = 1 and sc2.RN_ORDER = p.RN_ORDER + 1