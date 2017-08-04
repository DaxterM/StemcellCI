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

All of these commands where executed from a ubunu linux jumphost that is on the same network as vsphere, the director and the deployments. Instructions for creating this jumphost are not in this guide.

1. Deploy Vsphere bosh director 
2. Configure cloud configuration
3. Bosh Deploy concourse 
4. Bosh deploy minio and create buckets
5. Manualy build Concourse Windows worker VM
6. Manualy build initial VM template and place in S3 Bucket
7. Create creds.yml file
8. set pipeline with creds.yml and run it 

# Deploy Vsphere bosh director 

```
# Install Bosh2 CLI
$ wget https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.28-linux-amd64
$ chmod +x bosh-cli-*
$ sudo mv bosh-cli-* /usr/local/bin/bosh

# Install Bosh2CLI create-env dependencies
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
  -v internal_cidr=
  -v internal_gw= 
  -v internal_ip= 
  -v vcenter_cluster= 
  -v network_name= 
  -v vcenter_ip= 
  -v vcenter_user= 
  -v vcenter_password= 
  -v vcenter_dc= 
  -v vcenter_vms= 
  -v vcenter_templates= 
  -v vcenter_ds=
  -v vcenter_disks=
  
# Alias deployed Director
$ bosh -e bosh.dir.ip.here  --ca-cert <(bosh int ./creds.yml --path /director_ssl/ca) alias-env bosh-1

# Log in to the Director
$ export BOSH_CLIENT=admin
$ export BOSH_CLIENT_SECRET=`bosh int ./creds.yml --path /admin_password`
 ```
# Configure cloud configuration

```

$ git clone https://github.com/DaxterM/StemcellCI/ ~/workspace/stemcellci

$ bosh -e bosh-1 update-cloud-config ~/workspace/stemcellci/Examples/cloud-config.yml 
-v network_name= 
-v internal_cidr=
-v internal_gw=
-v vcenter_cluster=
-v dns_ip=
-v concourse_ip=
-v minio_ip=

```
# Bosh  deploy  Concourse
```
# Generate Keys
$ cd ~/deployments/bosh-1
$ ssh-keygen -f tsakey -t rsa  -N ''
$ ssh-keygen -f workerkey -t rsa  -N '' 

# Upload Releases and Stemcells
$ bosh -e bosh-1 upload-release https://bosh.io/d/github.com/concourse/concourse
$ bosh -e bosh-1 upload-release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-runc-release
$ bosh -e bosh-1 upload-stemcell https://bosh.io/d/stemcells/bosh-vsphere-esxi-ubuntu-trusty-go_agent

# Deploy concourse. Replace variables 
$ bosh -e bosh-1 -d concourse deploy ~/workspace/stemcellci/Examples/concourse.yml \
	-v director_uuid= \
	-v concourse_ip= \
	-v concourse_url= \
	-v concourse_admin_password= \
	--var-file=host_public_key=~/deployments/bosh-1/tsakey.pub \
	--var-file=authorized_keys=~/deployments/bosh-1/workerkey.pub \
	--var-file=host_key=~/deployments/bosh-1/tsakey

```
# Bosh deploy Minio (Optional) ignore if you are using AWS or other S3 provider 

```
# Clone, Build, and upload release to director
$ git clone https://github.com/minio/minio-boshrelease ~/workspace/minio
$ cd ~/workspace/minio/
$ bosh create-release --name minio --force
$ bosh -e bosh-1 upload-release

# Deploy Minio in a single node config
$ bosh -e bosh-1 -d minio deploy ~/workspace/stemcellci/Examples/minio.yml \
	-v director_uuid= \
	-v minio_ip= \
	-v minio_password=
```
# Create S3 Buckets

Create the following buckets In minio or other S3 compatible store
* vmx-with-windows-update	
* bosh-windows-stemcells-pre-release-candidate
* bosh-windows-stemcells-release-candidate

If you using minio you can create them via the UI. Access minio via http://minio-ip:9000
