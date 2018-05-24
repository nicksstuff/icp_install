#!/bin/bash


export ICP_VERSION=2.1.0.3

#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
#DO NOT MODIFY BELOW
#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
export MY_IP=$(hostname --ip-address)

#-------------------------------------------------------------------------------------------
# CREATE DIRECTORY STRUCTURES
#-------------------------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "CREATE DIRECTORY STRUCTURE"
mkdir -p ~/INSTALL/LDAP
mkdir -p ~/INSTALL/KUBE/PV
mkdir -p ~/INSTALL/KUBE/CONFIG
mkdir -p ~/INSTALL/ISTIO



#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
# CREATE PRE INSTALL FILES
#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "CREATE PRE INSTALL SCRIPT"
cat <<EOA >~/INSTALL/1_preInstall.sh
#!/bin/bash


# Install Prerequisites
echo "Installing Prerequisites";
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common python-minimal

sudo sysctl -w vm.max_map_count=262144

sudo cat <<EOB >>/etc/sysctl.conf
  vm.max_map_count=262144
EOB

#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#sudo apt-get update
#sudo apt-get install docker-ce=17.09.0~ce-0~ubuntu





# Install Command Line Tools
echo "Installing Tools";
sudo apt-get update
sudo ufw disable
sudo apt install python

sudo apt-get --yes --force-yes install tree
sudo apt-get --yes --force-yes install htop
sudo apt-get --yes --force-yes install curl
sudo apt-get --yes --force-yes install unzip
sudo apt-get --yes --force-yes install iftop

echo "Creating SSH Key";
ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N ""
cat ~/.ssh/master.id_rsa.pub | sudo tee -a ~/.ssh/authorized_keys
ssh-copy-id -i ~/.ssh/master.id_rsa.pub root@$MY_IP


echo "Downloading ICP CE Docker Image";
sudo docker pull ibmcom/icp-inception:$ICP_VERSION

echo "Creating Cluster Directory";
cd ~/INSTALL
sudo docker run -e LICENSE=accept -v "$(pwd)/INSTALL":/data ibmcom/icp-inception:$ICP_VERSION cp -r cluster /data


echo "Adapting Host IP";

cat <<EOM >hosts
[master]
$MY_IP

[worker]
$MY_IP

[proxy]
$MY_IP

#[management]
#$MY_IP

#[va]
#$MY_IP
EOM


sudo mv hosts ~/INSTALL/cluster
sudo cp ~/.ssh/master.id_rsa ~/INSTALL/cluster/ssh_key
sudo chmod 400 ~/INSTALL/cluster/ssh_key

echo "Copy SSH Key";
sudo cp ~/.ssh/master.id_rsa ./cluster/ssh_key
sudo chmod 400 ./cluster/ssh_key
EOA

sudo chmod +x ~/INSTALL/1_preInstall.sh



#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
# CREATE INSTALL FILES
#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "CREATE INSTALL SCRIPT"
cat <<EOA >~/INSTALL/2_install.sh
#!/bin/bash

echo "Installing ICP CE";
cd ~/INSTALL/cluster
sudo docker run -e LICENSE=accept --net=host -t -v "$(pwd)/INSTALL/cluster":/installer/cluster ibmcom/icp-inception:$ICP_VERSION install | sudo tee install.log

EOA

sudo chmod +x ~/INSTALL/2_install.sh

#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
# CREATE POST INSTALL FILES
#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "CREATE POST INSTALL SCRIPT"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Waiting for connection to cluster...."

#-------------------------------------------------------------------------------------------
# INSTALL CommandLine
#-------------------------------------------------------------------------------------------
echo "  -----------------------------------------------------------------------------------------------------------"
echo "    Command Lines"

cat <<EOM >~/INSTALL/3_postInstall.sh
#!/bin/bash

# Install Command Line Tools
docker run -e LICENSE=accept --net=host -v /usr/local/bin:/data ibmcom/icp-inception:$ICP_VERSION cp /usr/local/bin/kubectl /data
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | sudo bash
sudo helm init --client-only

#INIT KUBECTL
mkdir ~/.kube
cp /var/lib/kubelet/kubectl-config ~/.kube/config

EOM

sudo chmod +x ~/INSTALL/3_postInstall.sh

echo "  -----------------------------------------------------------------------------------------------------------"
echo "    BASHRC"

cat <<\EOM >>~/.bashrc

#Insecure kubectl
alias kubectl_sys_insecure='kubectl -n kube-system'
alias kubectl_insecure='kubectl -s 127.0.0.1:8888'
EOM

#source .bashrc

#-------------------------------------------------------------------------------------------
# CREATE LDAP
#-------------------------------------------------------------------------------------------
echo "  -----------------------------------------------------------------------------------------------------------"
echo "    LDAP"

cat <<\EOM >~/INSTALL/LDAP/addldapcontent.ldif
# LDIF Export for dc=mycluster,dc=icp
# Server: My LDAP Server (127.0.0.1)
# Search Scope: sub
# Search Filter: (objectClass=*)
# Total Entries: 7
#
# Generated by phpLDAPadmin (http://phpldapadmin.sourceforge.net) on November 2, 2017 1:15 pm
# Version: 1.2.2

version: 1

# Entry 1: dc=mycluster,dc=icp
# dn: dc=mycluster,dc=icp
# dc: mycluster
# o: mycluster.icp
# objectclass: top
# objectclass: dcObject
# objectclass: organization

# Entry 2: cn=admin,dc=mycluster,dc=icp
# dn: cn=admin,dc=mycluster,dc=icp
# cn: admin
# description: LDAP administrator
# objectclass: simpleSecurityObject
# objectclass: organizationalRole
# userpassword: {SSHA}/0QRGFxQbSFfie/i1S0Y71535bcTVhUI

# Entry 3: ou=groups,dc=mycluster,dc=icp
dn: ou=groups,dc=mycluster,dc=icp
objectclass: organizationalUnit
objectclass: top
ou: groups

# Entry 4: cn=developers,ou=groups,dc=mycluster,dc=icp
dn: cn=developers,ou=groups,dc=mycluster,dc=icp
cn: developers
objectclass: groupOfUniqueNames
objectclass: top
uniquemember: uid=demo,ou=users,dc=mycluster,dc=icp
uniquemember: uid=user1,ou=users,dc=mycluster,dc=icp

# Entry 5: ou=users,dc=mycluster,dc=icp
dn: ou=users,dc=mycluster,dc=icp
objectclass: organizationalUnit
objectclass: top
ou: users

# Entry 6: uid=demo,ou=users,dc=mycluster,dc=icp
dn: uid=demo,ou=users,dc=mycluster,dc=icp
cn: demo
objectclass: inetOrgPerson
objectclass: organizationalPerson
objectclass: person
objectclass: top
sn: demo
uid: demo
userpassword: {MD5}/gHOKn+6yPr67XyYKgTiKQ==

# Entry 7: uid=user1,ou=users,dc=mycluster,dc=icp
dn: uid=user1,ou=users,dc=mycluster,dc=icp
cn: user1
objectclass: inetOrgPerson
objectclass: organizationalPerson
objectclass: person
objectclass: top
sn: user1
uid: user1
userpassword: {MD5}/gHOKn+6yPr67XyYKgTiKQ==

# Entry 8: uid=user2,ou=users,dc=mycluster,dc=icp
dn: uid=user2,ou=users,dc=mycluster,dc=icp
cn: user2
objectclass: inetOrgPerson
objectclass: organizationalPerson
objectclass: person
objectclass: top
sn: user2
uid: user2
userpassword: {MD5}/gHOKn+6yPr67XyYKgTiKQ==
EOM

cat <<EOM >>~/INSTALL/3_postInstall.sh

read -p "Install and configure OpenLDAP? [y,N]" DO_LDAP
if [[ \$DO_LDAP == "y" ||  \$DO_LDAP == "Y" ]]; then
  # Install OpenLDAP
  echo "Install OpenLDAP "
  sudo apt-get update
  sudo apt-get --yes --force-yes install slapd ldap-utils
  sudo dpkg-reconfigure slapd

  # Create LDAP Users
  echo "Create LDAP Users"
  ldapadd -x -D cn=admin,dc=mycluster,dc=icp -W -f  ~/INSTALL/LDAP/addldapcontent.ldif

  echo "Import LDAP Users "
  export ACCESS_TOKEN=\$(curl -k -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" -d "grant_type=password&username=admin&password=admin&scope=openid" https://$MY_IP:8443/idprovider/v1/auth/identitytoken --insecure | \
      python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")
  echo "\$ACCESS_TOKEN"
  curl -k -X POST --header "Authorization: bearer \$ACCESS_TOKEN" --header 'Content-Type: application/json' -d '{"LDAP_ID": "OPENLDAP", "LDAP_URL": "ldap://$MY_IP:389", "LDAP_BASEDN": "dc=mycluster,dc=icp", "LDAP_BINDDN": "cn=admin,dc=mycluster,dc=icp", "LDAP_BINDPASSWORD": "admin", "LDAP_TYPE": "Custom", "LDAP_USERFILTER": "(&(uid=%v)(objectclass=person))", "LDAP_GROUPFILTER": "(&(cn=%v)(objectclass=groupOfUniqueNames))", "LDAP_USERIDMAP": "*:uid","LDAP_GROUPIDMAP":"*:cn", "LDAP_GROUPMEMBERIDMAP": "groupOfUniqueNames:uniquemember"}' 'https://$MY_IP:8443/idmgmt/identity/api/v1/directory/ldap/onboardDirectory'


else
  echo "LDAP not configured"
fi

EOM



#-------------------------------------------------------------------------------------------
# CREATE PersistentVolumes
#-------------------------------------------------------------------------------------------
echo "  -----------------------------------------------------------------------------------------------------------"
echo "    PersistentVolumes"

cat <<EOM >~/INSTALL/KUBE/PV/pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol01rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol01rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol02rwm
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol02rwm
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol03rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol03rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol04rwm
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol04rwm
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol05rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol05rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol06rwm
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol06rwm
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol07rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol07rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol08rwm
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol08rwm
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol13rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol13rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol14rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol14rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol15rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol15rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol16rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol16rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol17rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol17rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfsvol18rwo
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /storage/nfsvol18rwo
    server: $MY_IP
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: dsxpv
  labels:
    assign-to: "user-home"
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: $MY_IP
    path: /storage/dsx
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: tra-data-pv
  labels:
    type: local
spec:
  persistentVolumeReclaimPolicy: Recycle
  capacity:
    storage: 8Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: $MY_IP
    path: /storage/TRA_data
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-stor
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: $MY_IP
    path: /storage/data-stor
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: hadr-stor
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: $MY_IP
    path: /storage/hadr-stor
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: etcd-stor
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: $MY_IP
    path: /storage/etcd-stor
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001
spec:
  capacity:
    storage: 4Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: $MY_IP
    path: /storage/pv0001
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0002
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: $MY_IP
    path: /storage/pv0002
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: cam-mongo-pv
  labels:
    type: cam-mongo
spec:
  capacity:
    storage: 15Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: mycluster.icp
    path: /storage/CAM_db
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: cam-bpd-appdata-pv
  labels:
    type: cam-bpd-appdata
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: mycluster.icp
    path: /storage/CAM_bpd
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: cam-terraform-pv
  labels:
    type: cam-terraform
spec:
  capacity:
    storage: 15Gi
  accessModes:
    -  ReadWriteMany
  nfs:
    server: mycluster.icp
    path: /storage/CAM_terraform
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: cam-logs-pv
  labels:
    type: cam-logs
spec:
  capacity:
    storage: 10Gi
  accessModes:
    -  ReadWriteMany
  nfs:
    server: mycluster.icp
    path: /storage/CAM_logs  
EOM


cat <<\EOM >>~/INSTALL/3_postInstall.sh
read -p "Install and configure PersistentVolumes? [y,N]" DO_PV
if [[ $DO_PV == "y" ||  $DO_PV == "Y" ]]; then
  # Create PersistentVolumes
  echo "Install NFS Server"
  sudo apt-get --yes --force-yes install nfs-kernel-server

  # Create NFS Directories
  echo "Create NFS Directories"
  sudo mkdir -p /storage/
  sudo mkdir -p /storage/nfsvol01rwo
  sudo mkdir -p /storage/nfsvol02rwm
  sudo mkdir -p /storage/nfsvol03rwo
  sudo mkdir -p /storage/nfsvol04rwm
  sudo mkdir -p /storage/nfsvol05rwo
  sudo mkdir -p /storage/nfsvol06rwm
  sudo mkdir -p /storage/nfsvol07rwo
  sudo mkdir -p /storage/nfsvol08rwm
  sudo mkdir -p /storage/nfsvol11rwo
  sudo mkdir -p /storage/nfsvol12rwo
  sudo mkdir -p /storage/nfsvol13rwo
  sudo mkdir -p /storage/nfsvol14rwo
  sudo mkdir -p /storage/nfsvol15rwo
  sudo mkdir -p /storage/nfsvol16rwo
  sudo mkdir -p /storage/nfsvol17rwo
  sudo mkdir -p /storage/nfsvol18rwo
  sudo mkdir -p /storage/dsx
  sudo mkdir -p /storage/TRA_data
  sudo mkdir -p /storage/data-stor
  sudo mkdir -p /storage/hadr-stor
  sudo mkdir -p /storage/etcd-stor
  sudo mkdir -p /storage/pv0001
  sudo mkdir -p /storage/pv0002
  sudo mkdir -p /storage/CAM_db
  sudo mkdir -p /storage/CAM_logs
  sudo mkdir -p /storage/CAM_terraform
  sudo mkdir -p /storage/CAM_bpd

  sudo chmod -R 777 /storage
  sudo chown -R nobody:nogroup /storage

  # Configure NFS
  echo "Configure NFS"
  echo "/storage           *(rw,sync,no_subtree_check,async,insecure,no_root_squash)" | sudo tee -a /etc/exports
  sudo systemctl restart nfs-kernel-server
  sudo exportfs -a


  # Create PersistentVolumes
  echo "Create PersistentVolumes"
  kubectl apply -f ~/INSTALL/KUBE/PV/pv.yaml
else
  echo "PersistentVolumes not configured"
fi

EOM


#-------------------------------------------------------------------------------------------
# ISTIO INSTALL
#-------------------------------------------------------------------------------------------
echo "  -----------------------------------------------------------------------------------------------------------"
echo "    ISTIO"

cat <<\EOM >>~/.bashrc

function istio_test()
{
echo "TEST HELLOWORLD";
for i in `seq 1 200000`; do curl http://$(hostname --ip-address):31461/hello; done
}

function istio_V1()
{
echo "Only V1";
istioctl delete routerules helloworld-default --namespace default
istioctl create -f ~/INSTALL/ISTIO/istio-0.7.1/routingrule_100_0.yaml
}

function istio_BOTH()
{
echo "V1 and V2";
istioctl delete routerules helloworld-default --namespace default
istioctl create -f ~/INSTALL/ISTIO/istio-0.7.1/routingrule_50_50.yaml
}


function istio_V2()
{
echo "Only V2";
istioctl delete routerules helloworld-default --namespace default
istioctl create -f ~/INSTALL/ISTIO/istio-0.7.1/routingrule_0_100.yaml
}


function istio_remove_routingrule()
{
echo "Remove Routing Rule";
istioctl delete routerules helloworld-default --namespace default
}


function istio_helloworld()
{
echo "Starting Hello World";
#kubectl apply -f ~/INSTALL/ISTIO/istio-0.7.1/samples/helloworld/helloworld.yaml
kubectl create -f <(istioctl kube-inject -f ~/INSTALL/ISTIO/istio-0.7.1/samples/helloworld/helloworld.yaml)
}


function istio_helloworld_stop()
{
echo "Stopping Hello World";
kubectl delete -f ~/INSTALL/ISTIO/istio-0.7.1/samples/helloworld/helloworld.yaml
}
EOM

cat <<\EOM >>~/INSTALL/ISTIO/ingress.yaml
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": "istio-ingress",
    "namespace": "istio-system",
    "labels": {
      "istio": "ingress"
    },
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"labels\":{\"istio\":\"ingress\"},\"name\":\"istio-ingress\",\"namespace\":\"istio-system\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":80},{\"name\":\"https\",\"port\":443}],\"selector\":{\"istio\":\"ingress\"},\"type\":\"LoadBalancer\"}}\n"
    }
  },
  "spec": {
    "ports": [
      {
        "name": "http",
        "protocol": "TCP",
        "port": 80,
        "targetPort": 80,
        "nodePort": 31461
      },
      {
        "name": "https",
        "protocol": "TCP",
        "port": 443,
        "targetPort": 443,
        "nodePort": 31393
      }
    ],
    "selector": {
      "istio": "ingress"
    },
    "clusterIP": "10.0.0.91",
    "type": "LoadBalancer",
    "sessionAffinity": "None",
    "externalTrafficPolicy": "Cluster"
  }
}
EOM

#source .bashrc

cat <<\EOM >>~/INSTALL/3_postInstall.sh
read -p "Install and configure ISTIO? [y,N]" DO_ISTIO
if [[ $DO_ISTIO == "y" ||  $DO_ISTIO == "Y" ]]; then
  # Install ISTIO
  echo "Install ISTIO"
  cd ~/INSTALL/ISTIO

  wget https://github.com/istio/istio/releases/download/0.7.1/istio-0.7.1-linux.tar.gz
  tar -xzf istio-0.7.1-linux.tar.gz
  export PATH="$PATH:~/INSTALL/ISTIO/istio-0.7.1/bin"

  cd istio-0.7.1

  sudo cp bin/istioctl /usr/local/bin/

  # Create ISTIO
  echo "Create ISTIO Resources"

  cd ~/INSTALL/ISTIO/istio-0.7.1

  kubectl apply -f ./install/kubernetes/istio.yaml

  kubectl -n istio-system delete -f ~/INSTALL/ISTIO/ingress.yaml
  kubectl -n istio-system apply -f ~/INSTALL/ISTIO/ingress.yaml


cat <<\EOR >~/INSTALL/ISTIO/istio-0.7.1/routingrule_100_0.yaml
  apiVersion: config.istio.io/v1alpha2
  kind: RouteRule
  metadata:
    name: helloworld-default
    namespace: default
  spec:
    destination:
      name: helloworld
    precedence: 1
    route:
    - labels:
        version: v1
      weight: 100
    - labels:
        version: v2
      weight: 0
EOR

cat <<\EOR >~/INSTALL/ISTIO/istio-0.7.1/routingrule_50_50.yaml
  apiVersion: config.istio.io/v1alpha2
  kind: RouteRule
  metadata:
    name: helloworld-default
    namespace: default
  spec:
    destination:
      name: helloworld
    precedence: 1
    route:
    - labels:
        version: v1
      weight: 50
    - labels:
        version: v2
      weight: 50
EOR

cat <<\EOR >~/INSTALL/ISTIO/istio-0.7.1/routingrule_0_100.yaml
  apiVersion: config.istio.io/v1alpha2
  kind: RouteRule
  metadata:
    name: helloworld-default
    namespace: default
  spec:
    destination:
      name: helloworld
    precedence: 1
    route:
    - labels:
        version: v1
      weight: 0
    - labels:
        version: v2
      weight: 100
EOR
else
  echo "ISTIO not configured"
fi


read -p "Install and configure ISTIO Sidecar Injection(not recommended)? [y,N]" DO_ISTIOSC
if [[ $DO_ISTIOSC == "y" ||  $DO_ISTIOSC == "Y" ]]; then
  ./install/kubernetes/webhook-create-signed-cert.sh \
      --service istio-sidecar-injector \
      --namespace istio-system \
      --secret sidecar-injector-certs

  kubectl apply -f install/kubernetes/istio-sidecar-injector-configmap-release.yaml

  cat install/kubernetes/istio-sidecar-injector.yaml | \
       ./install/kubernetes/webhook-patch-ca-bundle.sh > \
       install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

  kubectl apply -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
  kubectl label namespace default istio-injection=enabled
  kubectl get namespace -L istio-injection
else
  echo "ISTIO Sidecar Injection not configured"
fi

EOM





#-------------------------------------------------------------------------------------------
# ALERT Configuration
#-------------------------------------------------------------------------------------------
echo "  -----------------------------------------------------------------------------------------------------------"
echo "    Alert Manager"

cat <<\EOM >~/INSTALL/KUBE/CONFIG/alert-rules_config.yaml
{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": "alert-rules",
    "namespace": "kube-system",
    "labels": {
      "app": "monitoring-prometheus",
      "component": "prometheus"
    },
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"data\":{\"sample.rules\":\"\"},\"kind\":\"ConfigMap\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"monitoring-prometheus\",\"component\":\"prometheus\"},\"name\":\"alert-rules\",\"namespace\":\"kube-system\"}}\n"
    }
  },
  "data": {
    "sample.rules": "ALERT NodeMemoryUsage\n  IF (((node_memory_MemTotal-node_memory_MemFree-node_memory_Cached)/(node_memory_MemTotal)*100)) > 25\n  FOR 1m\n  LABELS {\n    severity=\"page\"\n  }\n  ANNOTATIONS {\n    SUMMARY = \"{{$labels.instance}}: High memory usage detected\",\n    DESCRIPTION = \"{{$labels.instance}}: Memory usage is above 75% (current value is: {{ $value }})\"\n  }\nALERT HighCPUUsage\n  IF ((sum(node_cpu{mode=~\"user|nice|system|irq|softirq|steal|idle|iowait\"}) by (instance, job)) - ( sum(node_cpu{mode=~\"idle|iowait\"}) by (instance,job)))/(sum(node_cpu{mode=~\"user|nice|system|irq|softirq|steal|idle|iowait\"}) by (instance, job)) * 100 > 2\n  FOR 1m\n  LABELS { \n    service = \"backend\" \n  }\n  ANNOTATIONS {\n    summary = \"High CPU Usage\",\n    description = \"This machine  has really high CPU usage for over 10m\",\n  }"
  }
}
EOM


cat <<\EOM >~/INSTALL/KUBE/CONFIG/monitoring-prometheus-alertmanager_config.yaml
{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": "monitoring-prometheus-alertmanager",
    "namespace": "kube-system",
    "labels": {
      "app": "monitoring-prometheus",
      "component": "alertmanager"
    },
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"data\":{\"alertmanager.yml\":\"global:\\nreceivers:\\n  - name: default-receiver\\nroute:\\n  group_wait: 10s\\n  group_interval: 5m\\n  receiver: default-receiver\\n  repeat_interval: 3h\"},\"kind\":\"ConfigMap\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"monitoring-prometheus\",\"component\":\"alertmanager\"},\"name\":\"monitoring-prometheus-alertmanager\",\"namespace\":\"kube-system\"}}\n"
    }
  },
  "data": {
    "alertmanager.yml": "global:\nreceivers:\n- name: default-receiver\n- name: slack_general\n  slack_configs:\n  - api_url:  'https://hooks.slack.com/services/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'\n    channel: '#devops'\nroute:\n  group_wait: 10s\n  group_interval: 5m\n  receiver: slack_general\n  repeat_interval: 3h"
  }
}
EOM




cat <<\EOM >>~/INSTALL/3_postInstall.sh
read -p "Install and configure Alert Manager? [y,N]" DO_AM
if [[ $DO_AM == "y" ||  $DO_AM == "Y" ]]; then
  # Create ALERTS
  echo "Create ALERTS"

  kubectl -n kube-system delete -f ~/INSTALL/KUBE/CONFIG/alert-rules_config.yaml
  kubectl -n kube-system delete -f ~/INSTALL/KUBE/CONFIG/monitoring-prometheus-alertmanager_config.yaml

  kubectl -n kube-system apply -f ~/INSTALL/KUBE/CONFIG/alert-rules_config.yaml
  kubectl -n kube-system apply -f ~/INSTALL/KUBE/CONFIG/monitoring-prometheus-alertmanager_config.yaml
else
  echo "Alert Manager not configured"
fi

EOM



cat <<\EOM >>~/INSTALL/3_postInstall.sh
read -p "Install and configure CALICO Commandline? [y,N]" DO_CAL
if [[ $DO_CAL == "y" ||  $DO_CAL == "Y" ]]; then
  # Create ALERTS
  echo "Download CALICO Commandline"
  docker run -v /root:/data --entrypoint=cp ibmcom/calico-ctl:v2.0.2 /calicoctl /data
  sudo cp /root/calicoctl /usr/local/bin/
  export ETCD_CERT_FILE=/etc/cfc/conf/etcd/client.pem
  export ETCD_CA_CERT_FILE=/etc/cfc/conf/etcd/ca.pem
  export ETCD_KEY_FILE=/etc/cfc/conf/etcd/client-key.pem
  export ETCD_ENDPOINTS=https://mycluster.icp:4001

else
  echo "CALICO Commandline not configured"
fi

EOM


#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
# CREATE IMAGE PRELOAD
#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "CREATE IMAGE PRELOAD SCRIPT"

cat <<\EOM >>~/INSTALL/4_imagePreload.sh
sudo docker pull ibmcom/ucds:6.2.7.1.960481
sudo docker pull ibmcom/ucda:6.2.7.1.960481
sudo docker pull ibmcom/ucdr:6.2.7.1.960481
sudo docker pull ibmcom/mq:9
sudo docker pull ibmcom/postgres:9.6.2
sudo docker pull ibmcom/cfc-jenkins-master:2.19.4-1.1
sudo docker pull ibmcom/transformation-advisor-db:1.5.0
sudo docker pull ibmcom/transformation-advisor-server:1.5.0
sudo docker pull ibmcom/transformation-advisor-ui:1.5.0
sudo docker pull ibmcom/ibmnode:8
sudo docker pull ibmcom/microclimate-portal:latest
sudo docker pull ibmcom/microclimate-theia:latest
sudo docker pull ibmcom/microclimate-file-watcher:latest
sudo docker pull ibmcom/microclimate-devops:latest
sudo docker pull busybox:latest
sudo docker pull ibmcom/icp-nodejs-sample:latest
sudo docker pull ibmcom/velocity-consumer
sudo docker pull ibmcom/velocity-ui

sudo docker pull ibmcom/skydive:0.15.0
sudo docker pull ibmcom/microclimate-jmeter


sudo docker pull websphere-liberty:8.5.5.9
sudo docker pull nodered/node-red-docker:0.18.5

sudo docker pull nginx
sudo docker pull tomcat:9.0
sudo docker pull sonarqube:6.5
sudo docker pull jenkins/jenkins:lts
sudo docker pull postgres:9.6
sudo docker pull gcr.io/google_containers/kubernetes-dashboard-amd64:v1.8.3
sudo docker pull elasticsearch:2
sudo docker pull jenkins/jenkins:2.60.3
sudo docker pull ibmcom/mariadb:10.2.10

sudo docker pull bitnami/mariadb:10.1.29-r1
sudo docker pull bitnami/mongodb:3.4.10-r0

sudo docker pull na.cumulusrepo.com/hcicp_dev/dsm-sidecar:0.3.0
sudo docker pull na.cumulusrepo.com/hcicp_dev/db2server_dec:11.1.2.2

sudo docker pull openliberty/open-liberty:latest

sudo docker pull istio/examples-helloworld-v1
sudo docker pull citizenstig/httpbin



sudo docker pull istio/istio-ca:0.7.1
sudo docker pull istio/sidecar_initializer:0.7.1
sudo docker pull istio/pilot:0.7.1
sudo docker pull istio/proxy_debug:0.7.1
sudo docker pull istio/proxy_init:0.7.1
sudo docker pull istio/mixer:0.7.1
sudo docker pull istio/examples-helloworld-v1
sudo docker pull istio/examples-helloworld-v2


sudo docker pull store/ibmcorp/icam-bpd-cds:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-bpd-mariadb:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-bpd-ui:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-broker:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-iaas:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-mongo:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-orchestration:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-portal-ui:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-provider-helm:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-provider-terraform:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-proxy:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-redis:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-service-composer-api:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-service-composer-ui:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-tenant-api:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-ui-basic:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-ui-connections:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-ui-instances:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-ui-templates:2.1.0.2-x86_64
sudo docker pull store/ibmcorp/icam-busybox:2.1.0.2-x86_64



docker login mycluster.icp:8500 -u admin -p admin
docker tag nginx mycluster.icp:8500/default/nginx
docker push mycluster.icp:8500/default/nginx


docker login
sudo docker pull store/ibmcorp/db2_developer_c:11.1.3.3-x86_64



#sudo docker pull bitnami/mariadb:10.1.26-r0
#sudo docker pull bitnami/wordpress:4.8.1-r0
#sudo docker pull bitnami/ghost:0.11.10-r2
#sudo docker pull ibmcom/datapower:7.6.0
#sudo docker pull sumologic/fluentd-kubernetes-sumologic:v1.4
#sudo docker pull traefik:1.4.3
#sudo docker pull ibmcom/websphere-traditional:latest
#sudo docker pull ibmcom/websphere-liberty
#sudo docker pull ibmcom/datapower:7.6.0
#sudo docker pull hybridcloudibm/dsx-dev-icp-dsx-core:v1.015
#sudo docker pull hybridcloudibm/dsx-dev-icp-zeppelin:v1.015
#sudo docker pull hybridcloudibm/dsx-dev-icp-jupyter:v1.015
#sudo docker pull hybridcloudibm/dsx-dev-icp-rstudio:v1.015
#sudo docker pull ibmcom/mb-tools:2.1.0
#sudo docker pull ibmcom/mb-jenkins:2.1.0
#sudo docker pull ibmcom/mb-jenkins-slave:2.5.2

#sudo docker pull store/ibmcorp/data_server_manager_dev:2.1.4.1
#sudo docker pull ibmcom/data_server_manager_sidecar:0.4.0-x86_64
#sudo docker pull store/ibmcorp/data_server_manager_dev:2.1.4.1-x86_64


EOM

sudo chmod +x ~/INSTALL/4_imagePreload.sh

echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "ALL DONE"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Please execute 'source ~/.bashrc'"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
