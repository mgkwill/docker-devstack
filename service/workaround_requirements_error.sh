#!/bin/bash
# file: workaround_requirements_error.sh
# info: AFTER devstack/requirements is cloned into /opt/stack/requirements, 
# This is currently broken and needs to be done manually or hacked into devstack
# we need to modify the upper_constraints.txt file to use packaging 16.8, 
# to satisfy setuptools 30.0 minimum requirements: 
# this feels horribly hacky, but I don't want to push a change into devstack until 
# this has been tested
UPPER_REQS_FILE="/opt/stack/requirements/upper-constraints.txt"
while [ ! -f "$UPPER_REQS_FILE" ] ; do 
    echo "waiting for $UPPER_REQS_FILE to appear"
    sleep 1
done
BAD_PACK="packaging===16.7"
GOOD_PACK="packaging===16.8"
while [ -z "$(grep $BAD_PACK $UPPER_REQS_FILE)" ]; do 
    echo "$(date) : $UPPER_REQS_FILE does not yet contain \"$BAD_PACK\""
    sleep 1
    # if this does not find the bad package, it's probably broken
done

sed -i "s:$BAD_PACK:$GOOD_PACK:" $UPPER_REQS_FILE

