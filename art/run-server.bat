@echo off
color 8
echo === RUNNING PSYCH ONLINE SERVER LOCALLY! ===

WHERE npm /Q
if %ERRORLEVEL% NEQ 0 (
echo Downloading node.js
curl.exe https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi -L -o node.msi
echo Installing node.js
msiexec.exe /i node.msi /quiet
del node.msi
echo Please re-open this file to finish installing NPM!
PAUSE
exit
)

if not exist _server (
echo Downloading server code...
curl.exe https://github.com/Snirozu/Funkin-Online-Server/archive/refs/heads/main.zip -L -o server.zip
echo Downloaded!

echo Unpacking...
tar -xf server.zip
del server.zip
ren Funkin-Online-Server-main _server
echo Done!
attrib +h _server /s /d

cd _server
echo Installing required libraries...
call npm i
echo Done!
) else (
    cd _server
)

npm start

cd ..
PAUSE