echo "Installing Prerequisites";
sudo apt-get  --yes --force-yes install apt-transport-https ca-certificates curl software-properties-common python-minimal

sudo sysctl -w vm.max_map_count=262144

sudo cat <<EOB >>/etc/sysctl.conf
  vm.max_map_count=262144
EOB

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get --yes --force-yes update
sudo apt-get install --yes docker-ce=17.09.0~ce-0~ubuntu

sudo ufw disable


mkdir INSTALL
cd ~/INSTALL/
 git clone https://github.com/niklaushirt/libertysimple.git
 cd ~/INSTALL/libertysimple
 docker build -t libertysimple:1.0.0 docker_100
 docker build -t libertysimple:1.1.0 docker_110
 docker build -t libertysimple:1.2.0 docker_120
 docker build -t libertysimple:1.3.0 docker_130
