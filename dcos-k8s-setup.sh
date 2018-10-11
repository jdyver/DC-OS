#!/bin/bash

# Get DC/OS Master Node URL

echo
echo " #################################"
echo " ### Verifying DC/OS CLI Setup ###"
echo " #################################"
echo

# Make sure the DC/OS CLI is available
result=$(which dcos 2>&1)
if [[ "$result" == *"no dcos in"* ]]
then
        echo
        echo " ERROR: The DC/OS CLI program is not installed. Please install it."
        echo " Follow the instructions found here: https://docs.mesosphere.com/1.10/cli/install/"
        echo " Exiting."
        echo
        exit 1
fi

# Get DC/OS Master Node URL
MASTER_URL=$(dcos config show core.dcos_url 2>&1)
if [[ $MASTER_URL != *"http"* ]]
then
        echo
        echo " ERROR: The DC/OS Master Node URL is not set."
        echo " Please set it using the 'dcos cluster setup' command."
        echo " Exiting."
        echo
        exit 1
fi

# Check if the CLI is logged in
result=$(dcos node 2>&1)
if [[ "$result" == *"No cluster is attached"* ]]
then
    echo
    echo " ERROR: No cluster is attached. Please use the 'dcos cluster attach' command "
    echo " or use the 'dcos cluster setup' command."
    echo " Exiting."
    echo
    exit 1
fi
if [[ "$result" == *"Authentication failed"* ]]
then
    echo
    echo " ERROR: Not logged in. Please log into the DC/OS cluster with the "
    echo " command 'dcos auth login'"
    echo " Exiting."
    echo
    exit 1
fi
if [[ "$result" == *"is unreachable"* ]]
then
    echo
    echo " ERROR: The DC/OS master node is not reachable. Is core.dcos_url set correctly?"
    echo " Please set it using the 'dcos cluster setup' command."
    echo " Exiting."
    echo
    exit 1

fi

echo
echo "DC/OS CLI Setup Correctly"
echo

#Configure Kubernetes CLI
read -p "Install DCOS Kubernetes CLI, ? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then

dcos package install kubernetes --cli

# Install marathon-lb for IaaS level ingest to K8s Framework
echo "Deploying Marathon-LB"

dcos package install marathon-lb
sleep 30

# Configure api server and deploy Kubernetes Dashboard over Local Host using Kube proxy

echo "Adding Kube-Proxy to DC/OS Cluster"
dcos marathon app add kube-proxy.json
echo
echo
echo
echo

echo "Deploying Kubernetes API Server URL in Kubeconfig"

echo Determing public node IP...
export PUBLICNODEIP=$(sudo bash findpublic_ips.sh | head -1 | sed "s/.$//" )
echo Public node ip: $PUBLICNODEIP
dcos kubernetes kubeconfig --name=kubeconfig \
    --apiserver-url=http://$PUBLICNODEIP \
    --insecure-skip-tls-verify
echo ------------------

if [ ${#PUBLICNODEIP} -le 6 ] ;
then
        read -p 'Enter Public IP manually: ' PUBLICNODEIP
        PUBLICNODEIP=$PUBLICNODEIP
        dcos kubernetes kubeconfig --name=kubeconfig \
            --apiserver-url=http://$PUBLICNODEIP \
            --insecure-skip-tls-verify

            kubectl proxy
fi

else
        echo no
fi
echo

echo "Finished! You can now execute the traefik.sh script to deploy the example web app with ingress and hostname headers"