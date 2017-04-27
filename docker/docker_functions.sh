function get_host_port_map {
    INSTANCE_ID="$1"
    PORT_MAP="$2/tcp"
    echo -n "port map from container $PORT_MAP to: "
    docker inspect --format="{{(index (index .NetworkSettings.Ports \"${PORT_MAP}\") 0).HostPort}}" $INSTANCE_ID
}

function show_container_port_mappings {
    INSTANCE_ID="$1"
    docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}} {{$p}} -> {{(index $conf 0).HostPort}} {{end}}' $INSTANCE_ID

}

echo
get_host_port_map $1 $2

echo -e "\nFull container port map (<container port> -> <host port>)"
show_container_port_mappings $1
