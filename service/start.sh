#!/bin/sh
# On docker run, Env Variables "STACK_PASS & SERV_HOST" should be set using -e
#  example 'docker run -e "STACK_PASS=stack" -e "SERV_HOST=192.168.0.5" compute'
# or overided below by uncommenting:
STACK_PASS="stack"
SERV_HOST="192.168.0.5"
# ODL_NETWORK should be set in the 'docker run' script
set -o nounset # throw an error if a variable is unset to prevent unexpected behaviors
ODL_NETWORK=${ODL_NETWORK}
DEVSTACK_HOME="/home/stack/devstack"
CONF_PATH=$DEVSTACK_HOME/local.conf

#Set Nameserver to google
echo nameserver 8.8.8.8 | sudo tee -a /etc/resolv.conf

# Start SSH Service
sudo service ssh start

# Start openvswitch
sudo service openvswitch-switch start

# START HERE: the following line throws an error
echo "stack:$STACK_PASS" | sudo chpasswd

# get container IP 
ip=`/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1`
# fix address binding issue in mysql
sudo sed -i 's:^bind-address = 0.0.0.0:#&:' /etc/mysql/my.cnf
sudo service mysql restart 

# update the ip of this host
sudo sed -i "s:\(HOST_IP=\).*:\1${ip}:" $CONF_PATH
sudo sed -i "s:\(SERVICE_HOST=\).*:\1${ip}:" $CONF_PATH

cd $DEVSTACK_HOME
git checkout origin/stable/newton

$DEVSTACK_HOME/stack.sh

