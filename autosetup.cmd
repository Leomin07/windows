@echo off
setlocal enabledelayedexpansion

REM === CONFIG ===
REM Configure user variables
set "USER_NAME=MinhTD"
set "USER_EMAIL=tranminhsvp@gmail.com"
set "SSH_KEY_FILE=%USERPROFILE%\.ssh\id_ed25519"

REM === Do not run as admin ===
REM Check if the script is running with Administrator privileges.
REM If so, display an error and exit, as Scoop should not be run as Admin.
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [ERROR] Please DO NOT run this script as Admin.
    pause
    exit /b 1
)

REM === Install Scoop if not present ===
REM Check if Scoop is already installed.
REM If not, proceed with Scoop installation.
where scoop >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Scoop...
    powershell -NoProfile -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; iwr -useb get.scoop.sh | iex"
) else (
    echo Scoop is already installed. Skipping.
)

REM === Add necessary buckets ===
REM Add additional repositories (buckets) to Scoop to enable more software installations.
echo.
echo === Adding necessary Scoop buckets ===
powershell -Command "scoop bucket add extras"
powershell -Command "scoop bucket add versions"
powershell -Command "scoop bucket add nerd-fonts"
powershell -Command "scoop bucket add nonportable"

REM === Install main software for Windows ===
REM Define the list of Windows applications to be installed using Scoop.
set apps=google-chrome brave vscode dbeaver tableplus alacritty kitty windows-terminal wsl2 wget postman telegram-desktop JetBrainsMono-NF mpv tree python nodejs yarn lazydocker

REM Iterate through each application in the list and check/install it.
for %%a in (%apps%) do (
    echo.
    echo ==== Checking and Installing %%a ====
    REM Check if the application is already installed via Scoop.
    powershell -Command "scoop status %%a" >nul 2>&1
    if %errorLevel% equ 0 (
        echo %%a is already installed. Skipping.
    ) else (
        echo Installing %%a...
        powershell -Command "scoop install %%a"
    )
)

REM === Install WSL Ubuntu if not present ===
REM Check if Ubuntu WSL is already installed.
REM If not, install Ubuntu as the default WSL distribution.
echo.
echo === Checking Ubuntu WSL ===
wsl -l -v | findstr /I "Ubuntu" >nul
if %errorLevel% neq 0 (
    echo Installing Ubuntu WSL...
    powershell -Command "wsl --install -d Ubuntu"
    echo Please restart your machine after installing Ubuntu WSL, then run the script again.
    pause
    exit /b 1
) else (
    echo Ubuntu WSL is already installed. Skipping.
)

REM === Send environment setup script to WSL ===
echo.
echo === Copying environment setup script to WSL ===
REM Define paths for the setup script within WSL and the local temporary file.
set "WSL_SCRIPT_PATH=/tmp/setup_wsl_env.sh"
set "LOCAL_SCRIPT_FILE=%TEMP%\setup_wsl_env.sh"

REM Create the content of the WSL environment setup script and write it to the temporary file.
> "%LOCAL_SCRIPT_FILE%" (
    echo #!/bin/bash
    echo set -e
    echo
    echo echo "=== Update & install essentials ==="
    echo sudo apt update && sudo apt upgrade -y
    echo sudo apt install -y git curl wget build-essential software-properties-common
    echo
    echo echo "=== Install Python, Node.js, Yarn ==="
    echo if command -v python3 &>/dev/null && command -v pip3 &>/dev/null; then
    echo     echo "Python and Pip are already installed. Skipping."
    echo else
    echo     sudo apt install -y python3 python3-pip
    echo fi
    echo
    echo if command -v node &>/dev/null; then
    echo     echo "Node.js is already installed. Skipping."
    echo else
    echo     curl -fsSL https://deb.nodesource.com/setup_18.x ^| sudo -E bash -
    echo     sudo apt install -y nodejs
    echo fi
    echo
    echo if command -v yarn &>/dev/null; then
    echo     echo "Yarn is already installed. Skipping."
    echo else
    echo     corepack enable
    echo     sudo npm install -g yarn
    echo fi
    echo
    echo "=== Define Docker installation function ==="
    echo install_docker() {
    echo   if command -v docker &>/dev/null; then
    echo     echo "✅ Docker is already installed. Skipping installation."
    echo     return
    echo   fi
    echo
    echo   echo "🚀 Installing Docker..."
    echo
    echo   # Update and install necessary packages
    echo   sudo apt-get update
    echo   sudo apt-get install -y ca-certificates curl
    echo
    echo   # Create keyrings directory if it doesn't exist
    echo   sudo install -m 0755 -d /etc/apt/keyrings
    echo
    echo   # Download and set permissions for Docker GPG key
    echo   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    echo   sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo
    echo   # Add Docker repository to sources list
    echo   echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \\"
    echo   "https://download.docker.com/linux/ubuntu \\"
    echo   "\$(. /etc/os-release && echo "\${UBUNTU_CODENAME:-\$VERSION_CODENAME}") stable" | \\"
    echo   "  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null"
    echo
    echo   # Update and install Docker
    echo   sudo apt-get update
    echo   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo
    echo   echo "✅ Docker installation completed."
    echo }
    echo
    echo "=== Install Docker ==="
    echo install_docker # Call the Docker installation function
    echo sudo usermod -aG docker \$USER # Add user to the docker group
    echo
    echo echo "=== Install fish, fisher, fzf, bat ==="
    echo if command -v fish &>/dev/null; then
    echo     echo "Fish is already installed. Skipping."
    echo else
    echo     sudo apt install -y fish
    echo fi
    echo
    echo if command -v fzf &>/dev/null; then
    echo     echo "fzf is already installed. Skipping."
    echo else
    echo     sudo apt install -y fzf
    echo fi
    echo
    echo if command -v bat &>/dev/null; then
    echo     echo "bat is already installed. Skipping."
    echo else
    echo     sudo apt install -y bat
    echo fi
    echo
    echo fish -c 'curl -sL https://git.io/fisher ^| source && fisher install jorgebucaran/fisher'
    echo fish -c 'fisher install gazorby/fish-abbreviation-tips jhillyerd/plugin-git jethrokuan/z jorgebucaran/autopair.fish'
    echo
    echo echo "=== Install Vim and Neovim ==="
    echo if command -v vim &>/dev/null; then
    echo     echo "Vim is already installed. Skipping."
    echo else
    echo     sudo apt install -y vim
    echo fi
    echo
    echo if command -v nvim &>/dev/null; then
    echo     echo "Neovim is already installed. Skipping."
    echo else
    echo     sudo apt install -y neovim
    echo fi
    echo
    echo echo "=== Configure Git ==="
    echo git config --global user.name "%USER_NAME%"
    echo git config --global user.email "%USER_EMAIL%"
    echo
    echo echo "=== Create SSH key (if not present) and configure ==="
    echo SSH_DIR="\$HOME/.ssh"
    echo SSH_KEY_FILE="\$SSH_DIR/id_ed25519"
    echo
    echo mkdir -p "\$SSH_DIR"
    echo chmod 700 "\$SSH_DIR"
    echo
    echo if [ -f "\$SSH_KEY_FILE" ]; then
    echo     echo "SSH key found at \$SSH_KEY_FILE. Setting permissions."
    echo     chmod 600 "\$SSH_KEY_FILE"
    echo     eval "\$(ssh-agent -s)"
    echo     ssh-add "\$SSH_KEY_FILE"
    echo else
    echo     echo "SSH key not found at \$SSH_KEY_FILE. Please ensure it's copied from Windows or generate a new one."
    echo     echo "Generating a new SSH key..."
    echo     ssh-keygen -t ed25519 -f "\$SSH_KEY_FILE" -N ""
    echo     eval "\$(ssh-agent -s)"
    echo     ssh-add "\$SSH_KEY_FILE"
    echo fi
    echo
    echo echo "=== Configure Neovim ==="
    echo mkdir -p "\$HOME/.config/nvim"
    echo echo "Neovim config directory created at \$HOME/.config/nvim"
    echo
    echo echo "=== WSL Environment Setup Complete! ==="
    echo echo "Please restart terminal or WSL for changes to take effect (e.g., docker group, default shell)."
)

REM Copy the WSL setup script to Ubuntu
echo Copying WSL setup script to Ubuntu...
wsl -d Ubuntu cp "%LOCAL_SCRIPT_FILE%" "%WSL_SCRIPT_PATH%"

REM Copy SSH key to WSL /tmp first, then the WSL script will move it to ~/.ssh
if exist "%SSH_KEY_FILE%" (
    echo Copying SSH key to WSL...
    wsl -d Ubuntu cp "%SSH_KEY_FILE%" /tmp/id_ed25519
) else (
    echo [WARNING] SSH key not found at "%SSH_KEY_FILE%". A new one will be generated in WSL if needed.
)

REM Execute the WSL setup script
echo Running WSL setup script...
wsl -d Ubuntu bash "%WSL_SCRIPT_PATH%"

echo.
echo === Windows & WSL Setup Complete! ===
echo Please restart your computer for all changes to take effect.
pause
exit /b 0