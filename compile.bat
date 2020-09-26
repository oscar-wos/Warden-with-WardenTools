@ECHO OFF

set "name=Warden-with-WardenTools"
set "file=warden"
C:\Users\user\Git\scripting\spcomp.exe "C:\Users\user\Git\%name%\addons\sourcemod\scripting\%file%.sp" -i="C:\Users\user\Git\%name%\addons\sourcemod\scripting\include"

xcopy "%file%.smx" "addons\sourcemod\plugins" /C /D /Y /I
xcopy "addons\sourcemod\translations\%file%.phrases.txt" "C:\Users\user\Desktop\steamcmd\csgo\csgo\addons\sourcemod\translations" /C /D /Y /I

move /Y "%file%.smx" "C:\Users\user\Desktop\steamcmd\csgo\csgo\addons\sourcemod\plugins\%file%.smx"
