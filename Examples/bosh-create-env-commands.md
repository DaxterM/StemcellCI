git clone https://github.com/cloudfoundry/bosh-deployment

Before running Create-env change the bosh.yml to point your local DNS server and increase the bosh disk size to 200_000 in /vsphere/cpi.yml . 

Update DNS here https://github.com/cloudfoundry/bosh-deployment/blob/master/bosh.yml#L30 
Update Disk here https://github.com/cloudfoundry/bosh-deployment/blob/master/vsphere/cpi.yml#L22


You will need to change these values and paths to match your env

bosh create-env /home/dax/bosh-deployment/bosh.yml \
  --state ./state.json \
  -o /home/dax/bosh-deployment/jumpbox-user.yml \
  -o /home/dax/bosh-deployment/vsphere/cpi.yml \
  --vars-store ./creds.yml \
  -v director_name=bosh \
  -v internal_cidr=10.193.55.0/24 \
  -v internal_gw=10.193.55.1 \
  -v internal_ip=10.193.55.104 \
  -v vcenter_cluster=Cluster \
  -v network_name="VM Network" \
  -v vcenter_ip=.pivotal.io \
  -v vcenter_user=administrator@vsphere.local \
  -v vcenter_password= \
  -v vcenter_dc=Datacenter \
  -v vcenter_vms=bosh_vms \
  -v vcenter_templates=bosh_templates \
  -v vcenter_ds=LUN01 \
  -v vcenter_disks=bosh_disks
  
  
You will need to change these value to match your env.   
bosh -e bosh-1 update-cloud-config /home/dax/bosh-deployment/vsphere/cloud-config.yml \
  -v network_name="VM Network" \
  -v internal_cidr=10.193.55.0/24 \
  -v internal_gw=10.193.55.1 \
  -v vcenter_cluster=Cluster
  
After setting this you will need to make a few more changes
1. Configure static IP addresess for minio and concourse
2. Create a concourseLinuxWorker VM Type
3. Configure IP range approraitly for the env you are using
4. Create a new disk type called xlarge for minio

You can see examples of the above in the cloud-config-example.yml 