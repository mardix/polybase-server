# --------------------------------------------------------------------------
# Polybase Server setup
#
# curl https://raw.githubusercontent.com/mardix/polybase-server/master/setup.sh > polybase-server-setup.sh
# chmod 755 polybase-server-setup.sh
# ./polybase-server-setup.sh
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------

# CONFIGURATION
POLYBASE_VERSION=1.0.0

# DEPENDENCIES VERSION
ARANGODB_VERSION=3.7.9-1
TYPESENSE_VERSION=0.19.0
INFLUXDB_VERSION=1.8
REDIS_VERSION=latest

#--------------------------------------------------------------------------
echo "------------------------------------------------"
echo "::Polybase server setup::"
echo
echo

# Main password
while true; do
    read -s -p "Enter Main Server Password: " MAINPWD
    echo
    read -s -p "Re-enter Main Server Password: " MAINPWD2
    echo
    [ "$MAINPWD" = "$MAINPWD2" ] && break
    echo "Passwords didn't match. Try again"
done
echo

# Update system
echo 
echo "=======>>> update system ..."
echo 
apt-get update
apt-get install -y wget curl cron build-essential
apt-get update

# Install Polybox
echo 
echo "=======>>> installing Polybox ..."
echo 
curl https://raw.githubusercontent.com/mardix/polybox/master/install.sh > polybox-install.sh
chmod 755 polybox-install.sh
./polybox-install.sh

# Install Redis
echo 
echo "------------------------------------------------"
echo "=======>>> installing Redis ..."
apt-get install -y redis-server
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf
sed -i 's/supervised.*/supervised systemd/g' /etc/redis/redis.conf
sed -i "s/# requirepass.*/requirepass $MAINPWD/g" /etc/redis/redis.conf
sudo systemctl restart redis.service


# Install ArangoDB
echo 
echo "------------------------------------------------"
echo "=======>>> installing ArangoDB "
echo 
curl -OL https://download.arangodb.com/arangodb37/DEBIAN/Release.key
sudo apt-key add - < Release.key
echo 'deb https://download.arangodb.com/arangodb37/DEBIAN/ /' | sudo tee /etc/apt/sources.list.d/arangodb.list
sudo apt-get install apt-transport-https
sudo apt-get update
echo arangodb3 arangodb3/password password "$MAINPWD" | debconf-set-selections
echo arangodb3 arangodb3/password_again password "$MAINPWD" | debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q arangodb3=$ARANGODB_VERSION
sed -i 's/endpoint = tcp:\/\/127.0.0.1:8529/endpoint = tcp:\/\/0.0.0.0:8529/g' /etc/arangodb3/arangod.conf
sudo systemctl start arangodb3
sudo systemctl enable arangodb3
sudo systemctl restart arangodb3

# Install Typesense
echo 
echo "------------------------------------------------"
echo "=======>>> installing Typesense "
echo 
curl https://dl.typesense.org/releases/$TYPESENSE_VERSION/typesense-server-$TYPESENSE_VERSION-amd64.deb -o typesense-server.deb
apt install -y ./typesense-server.deb
sudo systemctl enable typesense-server
sudo systemctl restart typesense-server

# Install InfluxDB 1.8
echo 
echo "------------------------------------------------"
echo "=======>>> installing Influxdb "
echo 
curl -s https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt-get update && sudo apt-get install influxdb
sudo systemctl unmask influxdb.service
sudo systemctl start influxdb
sed -i 's/# auth-enabled = false/auth-enabled = true/g' /etc/influxdb/influxdb.conf
sed -i 's/# pprof-auth-enabled = false/pprof-auth-enabled = true/g' /etc/influxdb/influxdb.conf
sed -i 's/# ping-auth-enabled = false/ping-auth-enabled = true/g' /etc/influxdb/influxdb.conf
influx -execute "CREATE USER root WITH PASSWORD '$MAINPWD' WITH ALL PRIVILEGES"
sudo systemctl restart influxdb

echo "::Polybase server setup completed::"
echo
echo "------------------------------------------------"
# EOF

