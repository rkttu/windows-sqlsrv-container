$OSVer = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$Arch = "$env:PROCESSOR_ARCHITECTURE".ToLowerInvariant()

$ImageTag = '{0}.{1}.{2}.{3}-{4}' -f `
  $OSVer.CurrentMajorVersionNumber, `
  $OSVer.CurrentMinorVersionNumber, `
  $OSVer.CurrentBuild, $OSVer.UBR, $Arch

$LocalImagePath = "mssqldev:$ImageTag"

if ($(docker images -q $LocalImagePath) -eq '') {
  throw "Cannot find $LocalImagePath"
}

$ContainerName = 'mssqldev'

if ($(docker ps -f name="$ContainerName" -q -a) -ne $null) {
  $Decision = $Host.UI.PromptForChoice( `
    'Confirmation', `
    'The container {0} is already exists. Remove and re-create the container?' -f $ContainerName, `
    ('&Yes', '&No'), 1)
  if ($Decision -eq 0) {
    docker stop $ContainerName
    docker rm $ContainerName
  }
}

if ($(docker ps -f name="$ContainerName" -q) -ne $null) {
  throw "The container $ContainerName already running."
}

$DbDirectory = Join-Path -Path $HOME -ChildPath 'My Database'
if (-not (Test-Path -Path $DbDirectory -Type Container)) {
  New-Item -Type Directory -Path $DbDirectory | Out-Null
}

$DbConfig = Join-Path -Path $DbDirectory -ChildPath 'DatabaseConfig.json'
if (-not (Test-Path -Path $DbConfig -Type Leaf)) {
  Copy-Item -Path '.\DatabaseConfig.json' -Destination $DbConfig -Force
}
$AttachDbConfig = ((Get-Content -Path $DbConfig | ConvertFrom-Json) | ConvertTo-Json -Depth 100 -Compress) -replace '"', "'"
Write-Output $AttachDbConfig

Add-Type -AssemblyName 'System.Web'
$SaPassword = [System.Web.Security.Membership]::GeneratePassword(8, 0)
Write-Host $("Generated SA Password: {0}" -f $SaPassword)

$SqlcmdCommand = $("sqlcmd.exe -S localhost -U sa -P '{0}' -d master" -f $SaPassword)

Write-Host
Write-Host "You can access to the instance with the command: "
Write-Host $SqlcmdCommand
Write-Host " - or - "
Write-Host "docker.exe exec -it $ContainerName sqlcmd"
Write-Host

docker.exe run -d `
  -p 1433:1433 `
  -v $('{0}:C:/db/' -f $DbDirectory.Replace('\\', '/')) `
  -e sa_password=$SaPassword `
  -e ACCEPT_EULA=Y `
  -e $('attach_dbs={0}' -f $AttachDbConfig) `
  --isolation=process `
  --name=$ContainerName `
  $LocalImagePath
