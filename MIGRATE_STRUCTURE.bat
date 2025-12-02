@echo off
REM ========================================
REM SCRIPT DE MIGRACION ROGU MOBILE
REM Arquitectura limpia: lib/src/
REM ========================================

echo.
echo ========================================
echo   INICIANDO MIGRACION DE ESTRUCTURA
echo ========================================
echo.

REM ====================================
REM FASE 1: MIGRAR CORE (utils, theme, config)
REM ====================================

echo [FASE 1] Migrando CORE (utils, theme, config)...

REM Mover utils
echo   - Moviendo utils...
xcopy /E /I /Y "lib\utils\*" "lib\src\core\utils\"

REM Mover theme
echo   - Moviendo theme...
xcopy /E /I /Y "lib\theme\*" "lib\src\core\theme\"

REM Mover config
echo   - Moviendo config...
xcopy /E /I /Y "lib\config\*" "lib\src\core\config\"

echo [FASE 1] Completada.
echo.

REM ====================================
REM FASE 2: MIGRAR MODELS
REM ====================================

echo [FASE 2] Migrando MODELS...

xcopy /E /I /Y "lib\models\*" "lib\src\data\models\"

echo [FASE 2] Completada.
echo.

REM ====================================
REM FASE 3: MIGRAR WIDGETS
REM ====================================

echo [FASE 3] Migrando WIDGETS...

xcopy /E /I /Y "lib\widgets\*" "lib\src\presentation\widgets\"

echo [FASE 3] Completada.
echo.

REM ====================================
REM FASE 4: MIGRAR STATE
REM ====================================

echo [FASE 4] Migrando STATE a core...

xcopy /E /I /Y "lib\state\*" "lib\src\core\state\"

echo [FASE 4] Completada.
echo.

REM ====================================
REM FASE 5: MIGRAR ROUTES
REM ====================================

echo [FASE 5] Migrando ROUTES a core/router...

xcopy /E /I /Y "lib\routes\*" "lib\src\core\router\"

echo [FASE 5] Completada.
echo.

REM ====================================
REM FASE 6: MIGRAR ASSETS
REM ====================================

echo [FASE 6] Migrando ASSETS a core...

xcopy /E /I /Y "lib\assets\*" "lib\src\core\assets\"

echo [FASE 6] Completada.
echo.

REM ====================================
REM ADVERTENCIA: NO ELIMINAR TODAVIA
REM ====================================

echo.
echo ========================================
echo   MIGRACION FISICA COMPLETADA
echo ========================================
echo.
echo IMPORTANTE:
echo - Las carpetas originales NO fueron eliminadas
echo - Primero actualiza los imports
echo - Luego verifica compilacion
echo - Finalmente ejecuta CLEANUP.bat
echo.
echo Archivos copiados a: lib\src\
echo.

pause
