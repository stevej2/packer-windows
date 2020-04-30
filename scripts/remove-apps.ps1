function Takeown-Registry($key) {
    # TODO does not work for all root keys yet
    switch ($key.split('\')[0]) {
        "HKEY_CLASSES_ROOT" {
            $reg = [Microsoft.Win32.Registry]::ClassesRoot
            $key = $key.substring(18)
        }
        "HKEY_CURRENT_USER" {
            $reg = [Microsoft.Win32.Registry]::CurrentUser
            $key = $key.substring(18)
        }
        "HKEY_LOCAL_MACHINE" {
            $reg = [Microsoft.Win32.Registry]::LocalMachine
            $key = $key.substring(19)
        }
    }

    # get administraor group
    $admins = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $admins = $admins.Translate([System.Security.Principal.NTAccount])

    # set owner
    $key = $reg.OpenSubKey($key, "ReadWriteSubTree", "TakeOwnership")
    $acl = $key.GetAccessControl()
    $acl.SetOwner($admins)
    $key.SetAccessControl($acl)

    # set FullControl
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($admins, "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
}

function Takeown-File($path) {
    takeown.exe /A /F $path
    $acl = Get-Acl $path

    # get administraor group
    $admins = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $admins = $admins.Translate([System.Security.Principal.NTAccount])

    # add NT Authority\SYSTEM
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($admins, "FullControl", "None", "None", "Allow")
    $acl.AddAccessRule($rule)

    Set-Acl -Path $path -AclObject $acl
}

function Takeown-Folder($path) {
    Takeown-File $path
    foreach ($item in Get-ChildItem $path) {
        if (Test-Path $item -PathType Container) {
            Takeown-Folder $item.FullName
        } else {
            Takeown-File $item.FullName
        }
    }
}

function Elevate-Privileges {
    param($Privilege)
    $Definition = @"
    using System;
    using System.Runtime.InteropServices;
    public class AdjPriv {
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr rele);
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
        [DllImport("advapi32.dll", SetLastError = true)]
            internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
        [StructLayout(LayoutKind.Sequential, Pack = 1)]
            internal struct TokPriv1Luid {
                public int Count;
                public long Luid;
                public int Attr;
            }
        internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
        internal const int TOKEN_QUERY = 0x00000008;
        internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
        public static bool EnablePrivilege(long processHandle, string privilege) {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = new IntPtr(processHandle);
            IntPtr htok = IntPtr.Zero;
            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
            tp.Count = 1;
            tp.Luid = 0;
            tp.Attr = SE_PRIVILEGE_ENABLED;
            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            return retVal;
        }
    }
"@
    $ProcessHandle = (Get-Process -id $pid).Handle
    $type = Add-Type $definition -PassThru
    $type[0]::EnablePrivilege($processHandle, $Privilege)
}

echo "Elevating priviledges for this process"
do {} until (Elevate-Privileges SeTakeOwnershipPrivilege)

echo "Uninstalling default apps"
$apps = @(
# default Windows 10 apps
"Microsoft.3DBuilder"
"Microsoft.Appconnector"
"Microsoft.BingFinance"
"Microsoft.BingNews"
"Microsoft.BingSports"
"Microsoft.BingWeather"
#"Microsoft.FreshPaint"
"Microsoft.Getstarted"
"Microsoft.MicrosoftOfficeHub"
"Microsoft.MicrosoftSolitaireCollection"
#"Microsoft.MicrosoftStickyNotes"
"Microsoft.Office.OneNote"
#"Microsoft.OneConnect"
"Microsoft.People"
"Microsoft.SkypeApp"
"Microsoft.Windows.Photos"
"Microsoft.WindowsAlarms"
#"Microsoft.WindowsCalculator"
"Microsoft.WindowsCamera"
"Microsoft.WindowsMaps"
"Microsoft.WindowsPhone"
"Microsoft.WindowsSoundRecorder"
"Microsoft.WindowsStore"
"Microsoft.XboxApp"
"Microsoft.ZuneMusic"
"Microsoft.ZuneVideo"
"microsoft.windowscommunicationsapps"
"Microsoft.MinecraftUWP"

# Threshold 2 apps
"Microsoft.CommsPhone"
"Microsoft.ConnectivityStore"
"Microsoft.Messaging"
"Microsoft.Office.Sway"


#Redstone apps
"Microsoft.BingFoodAndDrink"
"Microsoft.BingTravel"
"Microsoft.BingHealthAndFitness"
"Microsoft.WindowsReadingList"

# non-Microsoft
"9E2F88E3.Twitter"
"PandoraMediaInc.29680B314EFC2"
"Flipboard.Flipboard"
"ShazamEntertainmentLtd.Shazam"
"king.com.CandyCrushSaga"
"king.com.CandyCrushSodaSaga"
"king.com.*"
"ClearChannelRadioDigital.iHeartRadio"
"4DF9E0F8.Netflix"
"6Wunderkinder.Wunderlist"
"Drawboard.DrawboardPDF"
"2FE3CB00.PicsArt-PhotoStudio"
"D52A8D61.FarmVille2CountryEscape"
"TuneIn.TuneInRadio"
"GAMELOFTSA.Asphalt8Airborne"
#"TheNewYorkTimes.NYTCrossword"

# apps which cannot be removed using Remove-AppxPackage
#"Microsoft.BioEnrollment"
#"Microsoft.MicrosoftEdge"
#"Microsoft.Windows.Cortana"
#"Microsoft.WindowsFeedback"
#"Microsoft.XboxGameCallableUI"
#"Microsoft.XboxIdentityProvider"
#"Windows.ContactSupport"
)

foreach ($app in $apps) {
    echo "Trying to remove $app"

    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage

    Get-AppXProvisionedPackage -Online |
            where DisplayName -EQ $app |
            Remove-AppxProvisionedPackage -Online
}

echo "Force removing system apps"
$needles = @(
#"Anytime"
"BioEnrollment"
#"Browser"
"ContactSupport"
#"Cortana"       # This will disable startmenu search.
#"Defender"
"Feedback"
"Flash"
"Gaming"
#"InternetExplorer"
#"Maps"
"OneDrive"
#"Wallet"
#"Xbox"          # This will result in a bootloop since upgrade 1511
)

foreach ($needle in $needles) {
    echo "Trying to remove all packages containing $needle"

    $pkgs = (ls "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" |
            where Name -Like "*$needle*")

    foreach ($pkg in $pkgs) {
        $pkgname = $pkg.Name.split('\')[-1]

        Takeown-Registry($pkg.Name)
        Takeown-Registry($pkg.Name + "\Owners")

        Set-ItemProperty -Path ("HKLM:" + $pkg.Name.Substring(18)) -Name Visibility -Value 1
        New-ItemProperty -Path ("HKLM:" + $pkg.Name.Substring(18)) -Name DefVis -PropertyType DWord -Value 2
        Remove-Item      -Path ("HKLM:" + $pkg.Name.Substring(18) + "\Owners")

        dism.exe /Online /Remove-Package /PackageName:$pkgname /NoRestart
    }
}