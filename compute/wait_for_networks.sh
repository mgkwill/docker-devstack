source /home/stack/devstack/openrc admin demo
while ! openstack network list 2>/dev/null 
do 
    echo "[$(date)] Waiting for networks to become active..."
    sleep 5
done
cd /home/stack

/home/stack/restart.sh

