# SQL Server on Windows Container Simple Launcher

This script package contains a simple launcher for SQL Server within a Windows container. You can use this script as your alternative SQL server installation for your local workstation or laptop.

I looked down the GitHub repository `microsoft/mssql-docker` repository. But the repository reflects does not reflect the latest version of the Windows container base image. Therefore, you will have to use the Windows container always Hyper-V isolation mode, which leads to more memory consumption and slow performance on the developer machine.

This script checks your Windows OS version and then builds a SQL Server Windows container image with your exact Windows base image to provide process isolation-based containers. You may experience better performance than Hyper-V isolated containers.

This repository uses some code on the GitHub `microsoft/mssql-docker` repository.

## Prerequisites

- Latest Version of Docker Desktop for Windows [here](https://hub.docker.com/editions/community/docker-ce-desktop-windows).
- At least Windows 10 1809 -- or - Windows Server 2019 required.
- If you are using this script in Windows 10, you may need virtualization capability to enable Hyper-V feature.

## How to use

- Install Docker Desktop for Windows ()
- Activate the Windows container mode
- Run `build_image.ps1` script to build SQL server on Windows container image on your local environment
- Run `run_sqlserver.ps1` script to run SQL server Windows container
- You can now access your containerized SQL server via `localhost:1433`.
  - Run `show_logs.ps1` script to watch container's log.
  - Run `enter_sqlcmd.ps1` script to execute sqlcmd.exe tool in your container.

### PowerShell script arguments

Following arguments can be used with `build_image.ps1` script.

- `OS_VERSION_TAG`: Specify valid mcr.microsoft.com/windows/servercore tag for build a new image. Default vaule will be your host operating system version.

Following arguments can be used with `run_sqlserver.ps1` script.

- `SA_PWD`: Specify the System Administrator account password. This argument does not constrained by security enforcement policy of the Windows Server. Default password will be auto-generated.
- `OS_VERSION_TAG`: Specify valid mcr.microsoft.com/windows/servercore tag for build a new image. Default value will be your host operating system version.

## Create or attach databases

The first time, this script creates a configuration file in `%USERPROFILE%\My Database` directory. The auto-generated container instance `mssqldev` will mount this directory as `C:\db` folder to mount your existing databases or create new databases.

You may find the `DatabaseConfig.json` file on the directory. You can add a new entry to create a new database or match the file name and actual database file to connect the existing database into your new instance.

## Contribute

You can contribute to this repository at any rate.
