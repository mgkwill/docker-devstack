function show_docker_networks {
    docker network inspect -f "network::  {{.Name}}" $(docker network ls -q)
}

function show_containers_in_network {
    docker network inspect -f "{{range .Containers}}{{with .}}{{.Name}}: {{.IPv4Address}}|{{end}}{{end}}" $1
}

NETWORK_TYPE="overlay"
echo "Network Type:: $NETWORK_TYPE"
for NETWORK in $(docker network ls -q -f "Driver=${NETWORK_TYPE}") ; do
    echo -n "Containers in network: "
    docker network inspect -f '{{.Name}}' $NETWORK
    show_containers_in_network $NETWORK | tr "|" "\n"
done
