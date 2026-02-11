$PSVersionTable

Get-Process

$var1= 12
Write-Output $var1
$var1.GetType()

$maVariable = "Bonjour le monde!"
Write-Output $maVariable 

$maVariable = "42"
$maVariable.GetType()
$maVariableConvertie = [int]$maVariable
$maVariableConvertie.GetType()

New-Variable -Name PI -Value 3.14 -Option Constant
Write-Output $PI
$PI.GetType()

[int]$var = 12
[int]$nombre = Read-Host 'Entrez un nombre'
Write-Output $nombre

$global:varg = "Global"
function Test {
    $local:varg = "Local"
    Write-Output $varg
}
Test

$a = "Mon chat"
$b = " est très tannant"
$c = $a + $b
Write-Output $c

"Bonjour {0}, aujourd’hui nous sommes le {1}" -f "Alice", (Get-Date)

Get-Help Get-Process -Detailed
Get-Help Get-Process -Full
Get-Help Get-Process -Examples
Get-Help Get-Process -Online
Get-Command Get-* 
Get-Help *service* 
Update-Help

Get-Service -Name spooler
Get-ChildItem -Path C:\Windows
Remove-Item C:\Test -Recurse
Remove-Item fichier.txt -Force
Remove-Item fichier.txt -WhatIf
Stop-Service spooler -Confirm
Copy-Item a.txt b.txt -Verbose

Get-Service | Where-Object Status -eq 'Running'

1..3 | ForEach-Object {
    "Extérieur: $PSItem"
    1..2 | ForEach-Object {
        "Intérieur: $PSItem"
    }
}

Get-Process notepad | Stop-Process
Get-Process notepad | Stop-Process -Id $_.Id

Get-Random | Stop-Process
New-Object -TypeName PSObject -Property @{'Id' = (Get-Random)} | Stop-Process –WhatIf

Get-Service

$service = Get-Service -Name Spooler
$service.Status

$service | Get-Member

$texte = "powershell"
$texte.ToUpper()

$utilisateur = [PSCustomObject]@{
    Nom= "Dupont"
    Prenom= "Alice"
    Age= 30
    Service= "Informatique"
}
$utilisateur | Add-Member -NotePropertyMembers @{DateNaissance=[DateTime] '08/26/2004' }
$utilisateur

$result = Get-Childitem C:\Windows
$result | Get-Member
Get-Member -InputObject $result
$result[0]
$result[0].LastWriteTime
$result[0]| Get-Member

########################################################

#Exercice 2
##2.1
$PSVersionTable
##2.2
Get-Command -CommandType Cmdlet
##2.3
Get-Help Write-Warning

#Exercice 3
Get-ChildItem C:\Windows
Get-ChildItem -Directory C:\Windows 
Get-ChildItem -Directory C:\Windows | Sort-Object -Property LastWriteTime -Descending
Get-ChildItem -Directory C:\Windows | Sort-Object -Property LastWriteTime -Descending | Export-Csv C:\Users\rt\Desktop\R405\FileExport.csv -UseCulture

#Exercice 4
Copy-Item  C:\Users\rt\Desktop\R405  C:\Users\rt\Documents
New-Item -Name BackupR405 -ItemType Directory C:\Backup
Copy-Item  .\FileExport.csv  C:\Backup\BackupR405
Copy-Item  .\a.txt C:\Backup\BackupR405
Copy-Item  .\b.txt  C:\Backup\BackupR405
Compress-Archive -Path C:\Backup\* -DestinationPath C:\Users\rt\Desktop\R405\Backup.zip

#Exercice 5
Get-FileHash -Path C:\Users\rt\Desktop\R405\a.txt
#
#Algorithm       Hash                                                                   Path
#---------       ----                                                                   ----
#SHA256          F2ACA93B80CAE681221F0445FA4E2CAE8A1F9F8FA1E1741D9639CAAD222F537D       C:\Users\rt\Desktop\R405\a.… 
#SHA256          B5B0A08F95070FCAB64F12B50CFF874C132CDAFB9799B5596D6B2394816594F2       C:\Users\rt\Desktop\R405\a.… 

#Exercice 6
Get-Process
Get-Process | Where-Object WS -gt 200Mb
Get-Process | Where-Object WS -gt 200Mb | Select-Object ProcessName, WS

#Exercice 7 
function MaFonction {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Nom,
        [int]$Age
    )
    if ($PSCmdlet.ShouldProcess($Nom, "Affichage des informations")) {
        Write-Host "Nom : $Nom, Age : $Age"
    }
}
MaFonction "Pierre" 21
MaFonction

function MaFonction2 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$Nom
    )
    BEGIN {
        Write-Host "Début de la fonction"
    }
    PROCESS {
        Write-Host "Traitement de $Nom"
    }
    END {
        Write-Host "Fin de la fonction"
    }
}
"Pierre","Paul","Julie" | MaFonction2

function Compte-Fichiers {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [System.IO.FileInfo]$File
    )
    begin {
        Write-Host "Début de la fonction"
        $dll=0
        $exe=0
    }
    process {
        if ($File.Extension -eq ".dll") {
            $dll++
        }
        if ($File.Extension -eq ".exe") {
            $exe++
        }
    }
    end {
        Write-Host "Fin de la fonction"
        Write-Host "Il y a $dll DLL et $exe EXE"
    }
}
Get-ChildItem -Recurse -Path "C:\Windows" 2>$null | Compte-Fichiers 2>$null

