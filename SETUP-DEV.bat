@echo off
REM ============================================================================
REM NELNA MAINTENANCE SYSTEM - Full Stack Development Setup
REM ============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ============================================================================
echo NELNA MAINTENANCE SYSTEM - Setup Script
echo ============================================================================
echo.

REM Step 1: Start Database Services with Docker Compose
echo [STEP 1] Starting MySQL and Redis with Docker Compose...
echo.
docker-compose up -d mysql redis

if !errorlevel! equ 0 (
    echo ✓ Database services started successfully
) else (
    echo ✗ Failed to start database services
    echo Make sure Docker Desktop is running
    pause
    exit /b 1
)

timeout /t 15 /nobreak
echo.

REM Step 2: Backend Setup
echo ============================================================================
echo [STEP 2] Setting up Backend...
echo ============================================================================
echo.

cd backend

echo Installing backend dependencies...
call npm install

if !errorlevel! equ 0 (
    echo ✓ Dependencies installed
) else (
    echo ✗ Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Running database migrations...
call npx prisma migrate dev --name init --skip-generate 2>nul

if !errorlevel! equ 0 (
    echo ✓ Database migrations completed
) else (
    echo ℹ Migrations may have already been applied
)

echo.
echo Seeding database with sample data...
call npx prisma db seed

if !errorlevel! equ 0 (
    echo ✓ Database seeded successfully
    echo   Default credentials: admin@nelna.com / Admin@123
) else (
    echo ℹ Database seeding completed (may have existing data)
)

echo.
echo ✓ Backend setup completed
echo.

REM Step 3: Frontend Setup
echo ============================================================================
echo [STEP 3] Setting up Frontend...
echo ============================================================================
echo.

cd ..\frontend

if exist package.json (
    echo Installing frontend dependencies...
    call npm install
    
    if !errorlevel! equ 0 (
        echo ✓ Frontend dependencies installed
    ) else (
        echo ✗ Failed to install frontend dependencies
    )
) else (
    echo ⚠ Frontend package.json not found - skipping
)

echo.
echo ============================================================================
echo ✓ SETUP COMPLETE
echo ============================================================================
echo.
echo Next Steps:
echo.
echo 1. Start Backend (in new terminal):
echo    cd backend
echo    npm run dev
echo.
echo 2. Start Frontend (in new terminal):
echo    cd frontend
echo    npm run dev
echo.
echo 3. Access the application:
echo    - Backend API: http://localhost:3000/api/v1/health
echo    - Frontend: http://localhost:5173 (or as configured)
echo    - Database UI: http://localhost:5555 (Prisma Studio - optional)
echo    - phpMyAdmin: http://localhost:8081 (optional)
echo.
echo 4. Login with default admin account:
echo    Email: admin@nelna.com
echo    Password: Admin@123
echo.
echo ============================================================================
echo.

pause
