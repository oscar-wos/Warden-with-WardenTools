@ECHO OFF

set "name=Warden-with-WardenTools"
set "file=warden"
C:\Users\user\Documents\Git\scripting\spcomp.exe "C:\Users\user\Documents\Git\%name%\addons\sourcemod\scripting\%file%.sp" -i="C:\Users\user\Documents\Git\%name%\addons\sourcemod\scripting\include"

xcopy "%file%.smx" "addons\sourcemod\plugins" /C /D /Y /I
xcopy "addons\sourcemod\translations\%file%.phrases.txt" "C:\Users\user\Documents\srcds\steamapps\common\Counter-Strike Global Offensive Beta - Dedicated Server\csgo\addons\sourcemod\translations" /C /D /Y /I

move /Y "%file%.smx" "C:\Users\user\Documents\srcds\steamapps\common\Counter-Strike Global Offensive Beta - Dedicated Server\csgo\addons\sourcemod\plugins\%file%.smx"