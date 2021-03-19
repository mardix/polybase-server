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
# Configure packages version in case 
ARANGODB_VERSION=3.7.9-1
TYPESENSE_VERSION=0.19.0

#--------------------------------------------------------------------------
echo "------------------------------------------------"
echo "::Polybase server setup::"
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
echo 
while true; do
    read -s -p "Enter Redis Password: " password
    echo
    read -s -p "Re-enter Redis Password: " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Passwords didn't match. Try again"
done
echo
apt-get install -y redis-server
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf
sed -i 's/supervised.*/supervised systemd/g' /etc/redis/redis.conf
sed -i "s/# requirepass.*/requirepass $password/g" /etc/redis/redis.conf
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
sudo apt-get install arangodb3=$ARANGODB_VERSION
sudo systemctl start arangodb3
sudo systemctl enable arangodb3
sed -i 's/endpoint = tcp:\/\/127.0.0.1:8529/endpoint = tcp:\/\/0.0.0.0:8529/g' /etc/arangodb3/arangod.conf
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

# Setup backup
echo
echo 
echo "------------------------------------------------"
echo "=======>>> setting up backup system "
echo 
echo " - setting awscli..."
curl https://raw.githubusercontent.com/timkay/aws/master/aws -o aws
chmod +x aws
mv aws /usr/bin
touch ~/.awssecret
chmod go-rwx ~/.awssecret
echo
echo " - setting backup.sh..."
curl https://raw.githubusercontent.com/mardix/polybase-server/master/backup.sh > /etc/polybase-server-backup.sh
chmod 755 /etc/polybase-server-backup.sh
echo
echo " - setting cron file..."
rm -rf /etc/cron.d/polybase-server
curl https://raw.githubusercontent.com/mardix/polybase-server/master/cron > /etc/cron.d/polybase-server
echo
echo

echo "::Polybase server setup completed::"
echo
echo "------------------------------------------------"
# EOF