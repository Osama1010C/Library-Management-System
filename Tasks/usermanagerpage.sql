-- get sid and serial# 
SELECT sid, serial#, username, status
FROM v$session
WHERE blocking_session IS NOT NULL;
-- kill the session 
ALTER SYSTEM KILL SESSION '35,13721';