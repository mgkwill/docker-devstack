#source /home/stack/devstack/openrc admin demo
while ! wget http://$SERVICE_HOST/dashboard 2>/dev/null 
do 
    echo "[$(date)] Waiting for horizon to become active..."
    sleep 5
done
cd /home/stack

/home/stack/restart.sh

