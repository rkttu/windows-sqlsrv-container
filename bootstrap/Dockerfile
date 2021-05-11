ARG OS_VERSION=2004
FROM mcr.microsoft.com/windows/servercore:${OS_VERSION}

ENV exe "https://go.microsoft.com/fwlink/?linkid=835677"
ENV box "https://go.microsoft.com/fwlink/?linkid=835679"

ENV SA_PWD="_" \
    ATTACH_DBS="[]" \
    ACCEPT_EULA="_"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# make install files accessible
WORKDIR /

RUN Invoke-WebRequest -Uri $env:box -OutFile SQL.box ; \
        Invoke-WebRequest -Uri $env:exe -OutFile SQL.exe ; \
        Start-Process -Wait -FilePath .\SQL.exe -ArgumentList /qs, /x:setup ; \
        .\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS ; \
        Remove-Item -Recurse -Force SQL.exe, SQL.box, setup

RUN Stop-Service -Name 'MSSQLSERVER' ; \
        Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -Name 'tcpdynamicports' -Value '' ; \
        Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -Name 'tcpport' -Value 1433 ; \
        Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver' -Name 'LoginMode' -Value 2 ;

HEALTHCHECK CMD [ "sqlcmd", "-Q", "select 1" ]

COPY start.ps1 /
CMD .\start.ps1 -SA_PWD $env:SA_PWD -ACCEPT_EULA $env:ACCEPT_EULA -ATTACH_DBS \"$env:ATTACH_DBS\" -Verbose
