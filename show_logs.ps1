$ContainerName = 'mssqldev'

if ($null -eq $(docker ps -f name="$ContainerName" -q -a)) {
    throw "Please run the container before use this script."
}

docker.exe logs -f $ContainerName
