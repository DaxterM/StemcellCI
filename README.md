# StemcellCI

This repo contains concourse tasks definitions, example bosh manifiests, and documentation to automate the vSphere bosh windows stemcell creation process for a Pivotal cloud foundry windows cell using a concourse pipeline.  

# What does the pipeline do?
The pipeline will run all windows updates, install diego cell pre-reqs (HWC,.NET,bosh-agent,etc), harden the OS (Disable RDP, local security policy,etc), and upload a stemcell to an S3 bucket. The final job in the pipeline will run acceptance tests on the stemcell.

![Pipeline](https://github.com/DaxterM/StemcellCI/blob/master/Examples/pipeline.png)
# Requirements
1. Bosh director on Vsphere. see https://github.com/cloudfoundry/bosh-deployment/ and https://github.com/DaxterM/StemcellCI/blob/master/Examples/bosh-create-env-commands.md
2. Bosh deployed concourse that supports external workers see https://concourse.ci/clusters-with-bosh.html and https://github.com/DaxterM/StemcellCI/blob/master/Examples/concourse.yml
3. Stand alone concourse windows worker joined to the bosh deployed concourse env with the required software dependencies installed
4. S3 compatible storage. Bosh deployed minio works see https://github.com/minio/minio-boshrelease and https://github.com/DaxterM/StemcellCI/blob/master/Examples/minio.yml

# High level steps
1. Deploy Vsphere bosh director 
2. Setup director cloud config
3. Bosh Deploy concourse 
4. Bosh deploy minio and create buckets
5. Manualy build Concourse Windows worker VM
6. Manualy build initial VM template and place in S3 Bucket
7. Create creds.yml file
8. set pipeline with creds.yml and run it 

# Deploy Vsphere bosh director 

```
# Install Bosh2 CLI
# Bosh2 CLI URL for Darwin, Linux, Windows @ https://bosh.io/docs/cli-v2.html#install
$ wget https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.28-linux-amd64
$ chmod +x bosh-cli-*
$ sudo mv ~/Downloads/bosh-cli-* /usr/local/bin/bosh

#Install Bosh2CLI create-env dependencies
$ sudo apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3

$ git clone https://github.com/cloudfoundry/bosh-deployment ~/workspace/bosh-deployment

# Create a directory to keep Director deployment
$ mkdir -p ~/deployments/bosh-1

$ cd ~/deployments/bosh-1

# Increase bosh director disk size to support windows stemcells
$ sed -i.bak 's/20_000/200_000/' ~/workspace/bosh-deployment/vsphere/cpi.yml
# Change bosh DNS server from 8.8.8.8 to local DNS server (if you skip this step you will not be able to upload stemcells to the director)
$ sed -i.bak 's/8.8.8.8/Put_Internal_DNS_IP_Here/' ~/workspace/bosh-deployment/bosh.yml 


# Deploy a Director -- ./creds.yml is generated automatically
# Replace -v flags with details from your enviornmnet 
$ bosh create-env ~/workspace/bosh-deployment/bosh.yml \
  --state ./state.json \
  -o ~/workspace/bosh-deployment/vsphere/cpi.yml  \
  --vars-store ./creds.yml \
  -v director_name=bosh 
  -v internal_cidr=10.193.55.0/24 
  -v internal_gw=10.193.55.1 
  -v internal_ip=10.193.55.104 
  -v vcenter_cluster=Cluster 
  -v network_name="VM Network" 
  -v vcenter_ip=.pivotal.io 
  -v vcenter_user=administrator@vsphere.local 
  -v vcenter_password= 
  -v vcenter_dc=Datacenter 
  -v vcenter_vms=bosh_vms 
  -v vcenter_templates=bosh_templates 
  -v vcenter_ds=LUN01 
  -v vcenter_disks=bosh_disks
  
# Alias deployed Director
$ bosh -e 10.0.0.6 --ca-cert <(bosh int ./creds.yml --path /director_ssl/ca) alias-env bosh-1

# Log in to the Director
$ export BOSH_CLIENT=admin
$ export BOSH_CLIENT_SECRET=`bosh int ./creds.yml --path /admin_password`
 ```
