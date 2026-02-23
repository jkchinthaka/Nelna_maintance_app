@echo off
setlocal enabledelayedexpansion

cd /d "C:\Users\chint\OneDrive\Pictures\nelnamaintance app\Nelna_maintance_app\backend"

echo Running Prisma migration...
echo.

npx prisma migrate dev --name init

echo.
echo Migration completed with exit code: !errorlevel!

pause
