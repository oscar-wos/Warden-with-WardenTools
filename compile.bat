@ECHO OFF

set "name=Warden-with-WardenTools"
set "file=warden"
C:\Users\user\Documents\Git\scripting\spcomp.exe "C:\Users\user\Documents\Git\%name%\addons\sourcemod\scripting\%file%.sp" -i="C:\Users\user\Documents\Git\%name%\addons\sourcemod\scripting\include"

xcopy /s/e/y "%file%.smx" "C:\Users\user\Documents\srcds\steamapps\common\Counter-Strike Global Offensive Beta - Dedicated Server\csgo\addons\sourcemod\plugins\%file%.smx"
move /Y "%file%.smx" "addons\sourcemod\plugins"
