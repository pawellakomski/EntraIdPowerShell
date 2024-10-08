<#
    .SYNOPSIS
    Export-AADUsers.ps1

    .DESCRIPTION
    Eksportowanie informacji o użytkownikach z Entra ID do pliku CSV.
    OPROGRAMOWANIE JEST DOSTARCZANE W STANIE, W JAKIM SIĘ ZNAJDUJE, BEZ JAKIEJKOLWIEK GWARANCJI, WYRAŹNEJ LUB DOROZUMIANEJ, W TYM MIĘDZY INNYMI GWARANCJI PRZYDATNOŚCI HANDLOWEJ, PRZYDATNOŚCI DO OKREŚLONEGO CELU I NIENARUSZANIA PRAW.
   
    .LINK
    #

    .NOTES
    Autor:      Paweł Łakomski
#>

# Podłączenie do API Graph
Connect-MgGraph -Scopes "User.Read.All, UserAuthenticationMethod.Read.All"

# Zmienne pomocnicze
$log = Get-Date -f yyyyMMddhhmm
$plikCSV = "users-$log.csv"
$parametryUser = @{
    All = $true
}
$bar = 0
$userObjects = @()

# Zebranie info o wszystkich użytkownikach i policzenie użytkowników
Write-Host "Pobieranie uzytkownikow"
$users = Get-MgBetaUser @parametryUser
$allUsers = $users.Count
$allUsers = $allUsers-1

Write-Host "Petla"
# Dla każdego użytkownika na podstawie informacji z profilu
foreach ($index in 0..$allUsers) {
    $user = $users[$index]

    # Zarządzanie paskiem postępu
    $bar++
    $procent = ($bar / $allUsers) * 100
    $barParameters = @{
        Activity        = "Przetwarzanie uzytkownikow"
        Status          = "Uzytkownik nr $($index + 1) z $allUsers - $($user.userPrincipalName) - Ukonczono $($procent -as [int])%"
    }
    Write-Progress @barParameters

    $MFAData=Get-MgUserAuthenticationMethod -UserId $user.userPrincipalName
    
    # Tworzymy obiekt użytkownika z danymi z 
    $userObject = [PSCustomObject]@{
        "Imie"                      = $user.givenName
        "Nazwisko"                  = $user.surname
        "Nazwa wyswietlana"         = $user.displayName
        "UPN"                       = $user.userPrincipalName
        "Email"                     = $user.mail
        "Stanowisko"                = $user.jobTitle
        "Departament"               = $user.department
        "Organizacja"               = $user.companyName
        "Telefon"                   = $user.mobilePhone
        "Telefony inne"             = $user.businessPhones -join ','
        "Synchronizacja z AD DS"    = if ($user.onPremisesSyncEnabled) { "Tak" } else { "Nie" }
        "samAccountName"            = $user.OnPremisesSamAccountName
        "Stan konta"                = if ($user.accountEnabled) { "Wlaczone" } else { "Wylaczone" }
        "Data stworzenia konta"     = $user.createdDateTime
        "Ostatnie logowanie"        = if ($user.SignInActivity.LastSuccessfulSignInDateTime) { $user.SignInActivity.LastSuccessfulSignInDateTime } else { "No sign in" }
        "Licencja"                  = if ($user.assignedLicenses.Count -gt 0) { "Tak" } else { "Nie" }
        "MFAstatus"                 = "_"
        "email"                     = "-"
        "fido2"                     = "-"
        "app"                       = "-"
        "password"                  = "-"
        "phone"                     = "-"
        "softwareoath"              = "-"
        "tempaccess"                = "-"
        "hellobusiness"             = "-"
    }

     ForEach ($method in $MFAData) {
    
        Switch ($method.AdditionalProperties["@odata.type"]) {
          "#microsoft.graph.emailAuthenticationMethod"  { 
             $userObject.email = $true 
             $userObject.MFAstatus = "Enabled"
          } 
          "#microsoft.graph.fido2AuthenticationMethod"                   { 
            $userObject.fido2 = $true 
            $userObject.MFAstatus = "Enabled"
          }    
          "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod"  { 
            $userObject.app = $true 
            $userObject.MFAstatus = "Enabled"
          }    
          "#microsoft.graph.passwordAuthenticationMethod"                {              
                $userObject.password = $true 
                # Jeśli jest tylko hasło, to MFA nie jest włączone
                if($userObject.MFAstatus -ne "Enabled")
                {
                    $userObject.MFAstatus = "Disabled"
                }                
           }     
           "#microsoft.graph.phoneAuthenticationMethod"  { 
            $userObject.phone = $true 
            $userObject.MFAstatus = "Enabled"
          }   
            "#microsoft.graph.softwareOathAuthenticationMethod"  { 
            $userObject.softwareoath = $true 
            $userObject.MFAstatus = "Enabled"
          }           
            "#microsoft.graph.temporaryAccessPassAuthenticationMethod"  { 
            $userObject.tempaccess = $true 
            $userObject.MFAstatus = "Enabled"
          }           
            "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod"  { 
            $userObject.hellobusiness = $true 
            $userObject.MFAstatus = "Enabled"
          }                   
        }

    # Dodanie bieżącego użytkownika do kolekcji
    $userObjects += $userObject
}

# Zarządzanie paskiem postępu
Write-Progress -Activity "Przetwarzanie uzytkownikow" -Completed

# Eksport do CSV
$userObjects | Sort-Object "Nazwa wyswietlana" | Export-Csv -Path $plikCSV -NoTypeInformation -Encoding UTF8

Disconnect-MgGraph
