[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("Create","Delete")]
  [string]$Action,

  [Parameter(Mandatory=$true)]
  [string]$CsvPath
)

Import-Module ActiveDirectory

$DomainDN = "DC=rt,DC=local"
$Password = ConvertTo-SecureString "Password@123" -AsPlainText -Force

# Dossiers
$UsersDataPath = "C:\UsersData"
$ArchivesPath  = "C:\Archives"
$LogPath       = "C:\Log"

# Création du dossier de log
if (!(Test-Path $LogPath)) {
  New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Nom du fichier de log horodaté
$LogFile = Join-Path $LogPath ("Manage-ADUsers_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

function Write-Log {
  param(
    [string]$Message,
    [string]$Level = "INFO"
  )

  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
  Write-Host $line
  Add-Content -Path $LogFile -Value $line
}

# Vérification du CSV
if (!(Test-Path $CsvPath)) {
  Write-Log "Fichier CSV absent : $CsvPath" "ERROR"
  exit 1
}

# Création des dossiers racine
if ($PSCmdlet.ShouldProcess($UsersDataPath, "Créer le dossier racine UsersData")) {
  New-Item -Path $UsersDataPath -ItemType Directory -Force | Out-Null
}

if ($PSCmdlet.ShouldProcess($ArchivesPath, "Créer le dossier racine Archives")) {
  New-Item -Path $ArchivesPath -ItemType Directory -Force | Out-Null
}

# Import CSV
$users = Import-Csv $CsvPath

foreach ($u in $users) {

  $login = $u.Login.Trim()

  if ($Action -eq "Create") {

    $ou = $u.OU.Trim()

    $userExists = Get-ADUser -Filter "SamAccountName -eq '$login'" -ErrorAction SilentlyContinue

    if ($userExists) {
      Write-Log "Utilisateur déjà existant : $login" "WARN"
    }
    else {
      $ouDN = "OU=$ou,$DomainDN"

      if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess($ou, "Créer l'OU")) {
          New-ADOrganizationalUnit -Name $ou -Path $DomainDN -ProtectedFromAccidentalDeletion $false | Out-Null
          Write-Log "OU créée : $ou"
        }
      }

      if ($PSCmdlet.ShouldProcess($login, "Créer l'utilisateur AD")) {
        New-ADUser `
          -Name "$($u.Prenom) $($u.Nom)" `
          -GivenName $u.Prenom `
          -Surname $u.Nom `
          -SamAccountName $login `
          -Path $ouDN `
          -AccountPassword $Password `
          -Enabled $true `
          -ChangePasswordAtLogon $true

        Write-Log "Utilisateur créé : $login"
      }
    }

    $folder = "$UsersDataPath\$login"

    if (!(Test-Path $folder)) {
      if ($PSCmdlet.ShouldProcess($folder, "Créer le dossier utilisateur")) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Write-Log "Dossier créé : $folder"
      }

      $acl = Get-Acl $folder
      $account = "rt\$login"

      $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $account,
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
      )

      $acl.SetAccessRule($rule)

      if ($PSCmdlet.ShouldProcess($folder, "Appliquer les permissions NTFS")) {
        Set-Acl -Path $folder -AclObject $acl
        Write-Log "Permissions appliquées pour : $account"
      }
    }
    else {
      Write-Log "Dossier déjà existant : $folder" "WARN"
    }
  }

  elseif ($Action -eq "Delete") {

    $userExists = Get-ADUser -Filter "SamAccountName -eq '$login'" -ErrorAction SilentlyContinue

    if (-not $userExists) {
      Write-Log "Utilisateur introuvable : $login" "WARN"
    }
    else {
      $folder = "$UsersDataPath\$login"

      if (Test-Path $folder) {
        $date = Get-Date -Format "yyyyMMdd"
        $zipPath = "$ArchivesPath\${login}_$date.zip"

        if ($PSCmdlet.ShouldProcess($folder, "Créer l'archive ZIP")) {
          Compress-Archive -Path "$folder\*" -DestinationPath $zipPath -Force
          Write-Log "Archive créée : $zipPath"
        }

        if ($PSCmdlet.ShouldProcess($folder, "Supprimer le dossier original")) {
          Remove-Item -Path $folder -Recurse -Force
          Write-Log "Dossier supprimé : $folder"
        }
      }
      else {
        Write-Log "Dossier introuvable : $folder" "WARN"
      }

      if ($PSCmdlet.ShouldProcess($login, "Supprimer l'utilisateur AD")) {
        Remove-ADUser -Identity $login -Confirm:$false
        Write-Log "Utilisateur supprimé : $login"
      }
    }
  }
}