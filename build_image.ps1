$OSVer = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$Arch = "$env:PROCESSOR_ARCHITECTURE".ToLowerInvariant()

$ImageTag = '{0}.{1}.{2}.{3}-{4}' -f `
  $OSVer.CurrentMajorVersionNumber, `
  $OSVer.CurrentMinorVersionNumber, `
  $OSVer.CurrentBuild, $OSVer.UBR, $Arch

$MCRImagePath = 'mcr.microsoft.com/windows/servercore:{0}' -f $ImageTag
$LocalImagePath = "mssqldev:$ImageTag"

if ($(docker images -q $MCRImagePath) -eq $null) {
  Write-Output "Pulling $MCRImagePath"
  docker pull $MCRImagePath
} else {
  Write-Output "$MCRImagePath already cached."
}

if ($(docker images -q $MCRImagePath) -eq $null) {
  throw "Cannot pull $MCRImagePath"
}

docker build -t $LocalImagePath --isolation=process --build-arg OS_VERSION=$ImageTag .\bootstrap\
