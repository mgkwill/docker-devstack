#!/bin/sh
# On docker run, Env Variables "STACK_PASS & SERV_HOST" should be set using -e
#  example 'docker run -e "STACK_PASS=stack" -e "SERV_HOST=192.168.0.5" compute'
# or overided below by uncommenting:
#STACK_PASS="stack" 
#SERV_HOST="192.168.0.5"

#Set Nameserver to google
echo nameserver 8.8.8.8 | sudo tee -a /etc/resolv.conf

# Start SSH Service
sudo service ssh start

# Start openvswitch
sudo service openvswitch-switch start 

echo -e $STACK_PASS | sudo passwd stack

# Add/Configure local.conf - requires use of 'docker run -v :/home/stack/mnt
sudo chmod 766 /home/stack/local.conf
cp /home/stack/local.conf /home/stack/devstack/local.conf

sed -i "s/SERVICE_HOST=/SERVICE_HOST=$SERV_HOST/" /home/stack/devstack/local.conf

ip=`/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1`;  echo "HOST_IP=$ip" >> /home/stack/devstack/local.conf

/home/stack/devstack/stack.sh
