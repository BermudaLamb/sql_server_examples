/*
I was looking for a way to easily pass this to a SQL Server Stored Procedure 
and let the SQL parse it and determine the necessary joins. This is what I came up with:
*/

DECLARE @x varchar(250), @xx xml

-- If my incoming list of ids in my SP looks like this:

set @x = '3, 9, 10, 12, 14'

-- I can easily convert it into XML and query it like this:

set @xx = '<xml><e>' + REPLACE(@x,', ','</e><e>') + '</e></xml>'
 
select @xx

/*
Returns:
<xml><e>3</e><e>9</e><e>10</e><e>12</e><e>14</e></xml>
*/

-- And

select @xx.query('for $d in /xml/e return data($d)')

/*
Returns:
3 9 10 12 14
*/

/*
For example, using XML path I can manually get the comma separated 
list of Terminal Names when I know the System IDs before hand
*/

select SUBSTRING((SELECT (', '+TerminalID) 
from ActiveInterface.dbo.SystemList sl with (nolock)
where SystemID in (3, 9, 10, 12, 14) for xml path('')), 3, 1000)

/*
How to get this without knowing the list beforehand was my big 
question, though. This is what I discovered:
*/

set nocount on
set arithabort on
 
DECLARE @x varchar(250), @xx xml
 
set @x = '3, 9, 10, 12, 14'
set @xx = '<xml><e>' + REPLACE(@x,', ','</e><e>') + '</e></xml>'

-- The inner query:
select * from (select N.value('.', 'int') SysID from @xx.nodes('xml/e') as T(N)) as x

/* 
Returns:
SysID
3
9
10
12
14
as individual rows
*/

select SUBSTRING((select (', ' + sl.TerminalId) 
from ActiveInterface.dbo.SystemList sl with (nolock)
inner join  (select N.value('.', 'int') SysID from @xx.nodes('xml/e') as T(N)) as x
on x.SysID = sl.SystemID for XML PATH('')), 3, 1000)

-- Returns:
/*
TERMINAL3, TERMINAL9, TERMINAL10, TERMINAL12, TERMINAL14
*/