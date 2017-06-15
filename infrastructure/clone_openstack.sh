#!/bin/bash
# file: clone_openstack.sh
# info: clones or mirrors a set of openstack repositories 
#   + repos cloned are specified by the _REPOS variable

_REPOS=( "keystone" "horizon" "requirements" "nova" "neutron" "networking-odl" "glance" )
DEST_DIR=$(pwd)

SETUP_MIRROR=false
MIRROR=""
DIR_SUFFIX=""
if [ "$SETUP_MIRROR" = "true" ] ; then 
    $MIRROR="--mirror"
    echo "Setting up mirrors instead of doing complete clone..."
    DIR_SUFFIX=".git"
fi

NUM_REPOS=${#_REPOS[@]}
#_BRANCH="stable/newton"
for (( i = 0; i < $NUM_REPOS; i++ )); do
	DESTINATION=$DEST_DIR/${_REPOS[$i]}${DIR_SUFFIX}
	SOURCE=https://git.openstack.org/openstack/${_REPOS[$i]}.git
    echo -e "\nCloning \"$SOURCE\" into $DESTINATION @ $(date) ... "
    git clone $MIRROR $SOURCE $DESTINATION
done

# vim: set sw=4 ts=4 :

