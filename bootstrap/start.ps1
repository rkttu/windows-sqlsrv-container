param
(
    [Parameter(Mandatory=$false)]
    [string]$SA_PWD,

    [Parameter(Mandatory=$false)]
    [string]$ACCEPT_EULA,

    [Parameter(Mandatory=$false)]
    [string]$ATTACH_DBS
)

if ("$ACCEPT_EULA".ToUpperInvariant() -ne 'Y') {
	Write-Verbose "ERROR: You must accept the End User License Agreement before this container can start."
	Write-Verbose "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."
    exit 1
}

# start the service
Write-Verbose "Starting SQL Server"
Start-Service -Name 'MSSQLSERVER'

if ($null -ne $SA_PWD)
{
    Write-Verbose "Changing SA login credentials"
    $sqlcmd = "ALTER LOGIN sa WITH PASSWORD=" + "'" + $SA_PWD + "'" + ",DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;ALTER LOGIN sa ENABLE;"
    & sqlcmd -Q $sqlcmd
}

$ATTACH_DBS_CLEANED = $ATTACH_DBS.TrimStart('\\').TrimEnd('\\')
$dbs = $ATTACH_DBS_CLEANED | ConvertFrom-Json

if ($null -ne $dbs -and $dbs.Length -gt 0)
{
    Write-Verbose "Attaching $($dbs.Length) database(s)"
	    
    Foreach ($db in $dbs) 
    {
        $saskey = ($db.saskey.length -gt 0)
        $files = @();
        $hasFile = $true;

        Foreach ($file in $db.dbFiles)
        {
            $hasFile = $hasFile -and (Test-Path -Type Leaf -Path $file)
            $files += "(NAME = N'$($db.dbName)_$($file -replace '\.', '_')', FILENAME = N'$($file)')";
            
            # check for a saskey and create one credential per blob Container                  
            if ($saskey)
            {
                $blob_container = (Split-Path $file).Replace('\','/');                                         
                $sql_credential = "IF NOT EXISTS (SELECT 1 FROM SYS.CREDENTIALS WHERE NAME = '" + $blob_container + "') BEGIN CREATE CREDENTIAL [" + $blob_container + "] WITH IDENTITY='SHARED ACCESS SIGNATURE', SECRET= '" + $db.saskey + "' END;"              
            
                Write-Verbose "sqlcmd -Q $($sql_credential)"
                & sqlcmd -Q $sql_credential
            }
        }
        $files = $files -join ","
        $forAttach = '';
        if ($hasFile) {
            $forAttach = ' FOR ATTACH '
        }
        $sqlcmd = "sp_detach_db $($db.dbName);CREATE DATABASE $($db.dbName) ON $($files) $forAttach ;"

        Write-Verbose "sqlcmd -Q $($sqlcmd)"
        & sqlcmd -Q $sqlcmd
	}
}

Write-Verbose "Started SQL Server."

$lastCheck = (Get-Date).AddSeconds(-2) 
while ($true) 
{ 
    Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 
    $lastCheck = Get-Date 
    Start-Sleep -Seconds 2 
}
