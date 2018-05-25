echo "Installing Prerequisites";
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common python-minimal

sudo sysctl -w vm.max_map_count=262144

sudo cat <<EOB >>/etc/sysctl.conf
  vm.max_map_count=262144
EOB

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce=17.09.0~ce-0~ubuntu

sudo ufw disable
