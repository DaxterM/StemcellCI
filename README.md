# StemcellCI

This repo contains concourse tasks, example bosh manifiests, and documentation to automate the vSphere bosh windows stemcell creation proccess for a Pivotal cloud foundry windows cell using a concourse pipeline.  

# What does the pipeline do?
The pipeline will run all windows updates, install diego cell pre-reqs (HWC,.NET,etc), harden the OS (Disable RDP, local security policy,etc), and upload a stemcell to an S3 bucket. The final job in the pipeline will run acceptance tests on the stemcell.

![Pipeline](https://github.com/DaxterM/StemcellCI/blob/master/Examples/pipeline.png)
# Requirements
1. Bosh director on Vsphere. see https://github.com/cloudfoundry/bosh-deployment/ and https://github.com/DaxterM/StemcellCI/blob/master/Examples/bosh-create-env-commands.md
2. Bosh deployed concourse that supports external workers see https://concourse.ci/clusters-with-bosh.html and https://github.com/DaxterM/StemcellCI/blob/master/Examples/concourse.yml
3. Stand alone concourse windows worker joined to the bosh deployed concourse env with the required software dependencies installed
4. S3 compatible storage. Bosh deployed minio works see https://github.com/minio/minio-boshrelease and https://github.com/DaxterM/StemcellCI/blob/master/Examples/minio.yml

# High level steps
1. Deploy Vsphere bosh director with cloud-config
2. Bosh Deploy concourse 
3. Bosh deploy minio 
4. Manualy build Concourse Windows worker VM
5. Manualy build initial VM template and place in S3 Bucket
6. Create creds.yml file
7. set pipeline with creds.yml and run it 
