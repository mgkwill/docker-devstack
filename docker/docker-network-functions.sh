#!/bin/bash
# file: find_service_node_IP.sh
# info: uses docker Go-templates to 
#       fn_show_docker_networks: list the docker-controlled networks by name with a Go template
#       fn_show_containers_in_network: list all the containers and their IP in a docker network
#       fn_list_containers_in_network: same as above with a different Go-template
# info: queries docker daemon with 'docker inspect' Go-templates
#       fn_docker_dns_lookup is a DNS-like function that returns the IPv4Address of a container,
#       +given the container's host name and the docker network to look in
       
function fn_show_docker_networks {
    docker network inspect -f "network::  {{.Name}}" $(docker network ls -q)
}

function fn_show_containers_in_network {
    # the "|" pipe is used to separate network tenants. Pipe through "tr "|" "\n" to sub newlines
    docker network inspect -f "{{range .Containers}}{{with .}}{{.Name}}: {{.IPv4Address}}|{{end}}{{end}}" $1
}

function fn_list_containers_in_network {
    # similar output as show_containers_in_network with different template
    # list all the nodes and their IP addresses
    docker network inspect -f '{{range $id, $conf := .Containers}}|{{$conf.Name}}:{{$conf.IPv4Address}}{{end}}' $NETWORK_NAME | tr "|" "\n"
}

function fn_show_overlay_tenants {
    NETWORK_TYPE=${NETWORK_TYPE:-"overlay"}
    echo "Network Type:: $NETWORK_TYPE"
    for NETWORK_NAME in $(docker network ls -q -f "Driver=${NETWORK_TYPE}") ; do
        echo -n "Containers in network: "
        docker network inspect -f '{{.Name}}' $NETWORK_NAME
        fn_show_containers_in_network $NETWORK_NAME | tr "|" "\n"
    done
}

function fn_docker_dns_lookup {
    NETWORK_NAME=$1
    HOST_NAME=$2
    # you can directly access key.Field with the (index <map> <key>) function
    docker network inspect -f "{{ (index .Containers \"${LONG_ID}\").IPv4Address  }}" $NETWORK_NAME
}

function fn_show_exposed_ports {
    echo "Exposed ports on $HOST_NAME:"
    docker inspect -f "{{json .Config.ExposedPorts }}" $HOST_NAME | python -m json.tool
}

function fn_lookup_mapped_host_port {
    # from https://docs.docker.com/engine/reference/commandline/inspect/#find-a-specific-port-mapping
    # [ in contrast with the technique used in fn_docker_dns_lookup, ]
    # The .Field syntax doesn’t work when the field name begins with a number, but 
    # the template language’s index function does. The .NetworkSettings.Ports 
    # section contains a map of the internal port mappings to a list of external 
    # address/port objects. To grab just the numeric public port, you use index to 
    # find the specific port map, and then index 0 contains the first object inside
    # of that. Then we ask for the HostPort field to get the public address.
    # notes: "80/tcp" is the key to search for in the NetworkSettings.Ports map (dictionary)
    #         The returned value in this lookup will be the mapped host port, e.g. 50080
    docker inspect -f "{{ (index (index .NetworkSettings.Ports \"80/tcp\" ) 0 ).HostPort }}" $HOST_NAME
}

HOST_NAME=${1:-service-node-o17}
LONG_ID=$(docker inspect -f "{{.Id}}" $HOST_NAME)
NETWORK_NAME=${2:-overlay-net}
echo
echo Docker container lookups::
echo fn_show_exposed_ports service-node-o17
fn_show_exposed_ports service-node-o17
echo
echo "fn_lookup_mapped_host_port \"80/tcp\""
fn_lookup_mapped_host_port
echo
echo Docker network lookups:::
echo IP address of host $HOST_NAME on network \"$NETWORK_NAME\"
fn_docker_dns_lookup $NETWORK_NAME $HOST_NAME
echo
echo fn_show_docker_networks: list the active docker networks
fn_show_docker_networks
echo 
echo fn_show_containers_in_network overlay-net
fn_show_containers_in_network overlay-net
echo
echo fn_list_containers_in_network overlay-net
fn_list_containers_in_network overlay-net
echo
echo fn_show_overlay_tenants
fn_show_overlay_tenants
echo
echo fn_docker_dns_lookup overlay-net service-node
fn_docker_dns_lookup overlay-net service-node
echo

