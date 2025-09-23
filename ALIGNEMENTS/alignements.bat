@echo off
echo ========================================
echo    Lancement automatique du script Python
echo ========================================
echo.

REM ============================
REM PARAMÈTRES MODIFIABLES
REM ============================
set DISTRO=Ubuntu
set CONDA_PATH=~/miniconda3/etc/profile.d/conda.sh
set CONDA_ENV=TOOLS_env
set PYTHON_SCRIPT=alignements.py
set STREAMLIT_URL=http://localhost:8501
REM ============================

REM Vérifier si WSL2 est en cours d'exécution
echo Vérification de WSL2...
wsl --list --running | findstr "%DISTRO%" >nul
if %errorlevel% neq 0 (
    echo Démarrage de %DISTRO%...
    wsl --distribution %DISTRO% --exec echo "%DISTRO% démarré"
    timeout /t 3 >nul
)

echo %DISTRO% est prêt !
echo.

REM Exécution du script Python dans WSL2 avec conda
echo Exécution du script Python dans %DISTRO%...
start "" %STREAMLIT_URL%
wsl --distribution %DISTRO% --exec bash -c "source %CONDA_PATH% && conda activate %CONDA_ENV% && streamlit run %PYTHON_SCRIPT%"
