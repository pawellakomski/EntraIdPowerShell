<#
    .SYNOPSIS
    Add-AADNewUsers.ps1

    .DESCRIPTION
    Dodawanie użytkowników utworzonych w przeciągu ostatnich 24h do okreslonej grupy AAD. Przed użyciem skonfiguruj właściwe uprawnienia na Graph API i we właściwy sposób użyj Connect-MgGraph. Wymagany scope: Application.ReadWrite.All, Directory.Read.All, GroupMember.ReadWrite.All, User.Read.All
    Ustaw właściwe ID grupy Entra ID w linii 25.

    OPROGRAMOWANIE JEST DOSTARCZANE W STANIE, W JAKIM SIĘ ZNAJDUJE, BEZ JAKIEJKOLWIEK GWARANCJI, WYRAŹNEJ LUB DOROZUMIANEJ, W TYM MIĘDZY INNYMI GWARANCJI PRZYDATNOŚCI HANDLOWEJ, PRZYDATNOŚCI DO OKREŚLONEGO CELU I NIENARUSZANIA PRAW.

    .LINK
    #

    .NOTES
    Autor:      Paweł Łakomski
#>

# Przed użyciem skonfiguruj właściwe uprawnienia na Graph API i we właściwy sposób użyj Connect-MgGraph. Wymagany scope: Application.ReadWrite.All, Directory.Read.All, GroupMember.ReadWrite.All, User.Read.All
# Connect-MgGraph

#ilosc dni wstecz, które sprawdzamy - do ustalenia/sprawdzenia
$wczoraj = (Get-date).AddDays(-2).ToString("yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'")
$users = Get-MgUser -All -Filter "CreatedDateTime ge $wczoraj"
$ilu - $users.Count
Write-Host "Znaleziono $ilu uzytkownikow"

foreach($user in $users)
{
    Write-Host "Dodaję $user.userPrincipalName" do grupy...
    New-MgGroupMember -GroupId '68fa1256-8c38-42b3-a1c2-b22939758671' -DirectoryObjectId $user.Id
}

Disconnect-MgGraph
