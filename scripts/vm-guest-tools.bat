
msiexec /qb /i C:\Windows\Temp\7zip.msi

echo "%install_vbox_tools%"

if "%PACKER_BUILDER_TYPE%" equ "vmware-iso" goto :vmware
if "%PACKER_BUILDER_TYPE%" equ "virtualbox-iso" goto :virtualbox


goto :done

:vmware

if exist "C:\Users\vagrant\windows.iso" (
    move /Y C:\Users\vagrant\windows.iso C:\Windows\Temp
)

if not exist "C:\Windows\Temp\windows.iso" (
    powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://softwareupdate.vmware.com/cds/vmw-desktop/ws/15.5.2/15785246/windows/packages/tools-windows.tar', 'C:\Windows\Temp\vmware-tools.tar')" <NUL
    cmd /c ""C:\Program Files\7-Zip\7z.exe" x C:\Windows\Temp\vmware-tools.tar -oC:\Windows\Temp"
    FOR /r "C:\Windows\Temp" %%a in (VMware-tools-windows-*.iso) DO REN "%%~a" "windows.iso"
    rd /S /Q "C:\Program Files (x86)\VMWare"
)

cmd /c ""C:\Program Files\7-Zip\7z.exe" x "C:\Windows\Temp\windows.iso" -oC:\Windows\Temp\VMWare"
cmd /c C:\Windows\Temp\VMWare\setup.exe /S /v"/qn REBOOT=R\"

del /Q "C:\Windows\Temp\vmware-tools.tar"
del /Q "C:\Windows\Temp\windows.iso"
rd /S /Q "C:\Windows\Temp\VMware"
goto :done

:virtualbox

if exist "C:\Users\vagrant\VBoxGuestAdditions.iso" (
echo "Found addiition ....."
    move /Y C:\Users\vagrant\VBoxGuestAdditions.iso C:\Windows\Temp
)

REM cmd /c ""C:\Program Files\7-Zip\7z.exe" x C:\Windows\Temp\VBoxGuestAdditions.iso -oC:\Windows\Temp\virtualbox"
REM cmd /c ""C:\Program Files\7-Zip\7z.exe" x D:\VBoxGuestAdditions.iso -oC:\Windows\Temp\virtualbox"
REM cmd /c for %%i in (C:\Windows\Temp\virtualbox\cert\vbox*.cer) do C:\Windows\Temp\virtualbox\cert\VBoxCertUtil add-trusted-publisher %%i --root %%i
cmd /c for %%i in (E:\cert\vbox*.cer) do E:\cert\VBoxCertUtil add-trusted-publisher %%i --root %%i
cmd /c E:\VBoxWindowsAdditions.exe /S
rem rd /S /Q "C:\Windows\Temp\virtualbox"

goto :done


:done
