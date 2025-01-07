@echo off

IF NOT EXIST "tmp" (
  mkdir tmp
)

wsl --terminate Ubuntu-22.04
if %errorlevel% equ 0 (
    echo Terminated WSL Ubuntu-22.04 
) else (
    echo Ubuntu not found, make sure the Ubuntu-22.04 is installed!!
    exit
)

echo Exporting Ubuntu-22.04.... this may take a minute 
wsl --export Ubuntu-22.04 tmp\ubuntuimage.tar 

if %errorlevel% equ 0 (
    echo Saved Ubuntu-22.04 image
    ) else (
        echo Unable to save Ubuntu-22.04 image. Make sure it is installed and named Ubuntu-22.04!!
)


IF EXIST "tmp\ubuntuimage.tar" (
    echo Creating tibcoplatform image
    wsl --import tibcoplatform . .\tmp\ubuntuimage.tar
    if %errorlevel% equ 0 (
        echo An image named 'tibcoplatform' was created successfully.
    ) else (
        echo Failed to create an image named 'tibcoplatform'. 
    )
)

del /f /s /q ".\tmp\*"
rmdir /s /q ".\tmp"