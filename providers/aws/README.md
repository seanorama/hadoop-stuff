Deploy HDP (Hortonworks Data Platform) on AWS using:

 - AWS CloudFormation
 - Apache Ambari Blueprints
 - shell scripts

Current status:

  - CloudFormation builds a simple cluster with a single master node
  - Then you trigger the Ambari build manually.

Note: I did not write the initial tempalte or scripts. This is a work in progress.

### Instructions

  - 1. Deploy a new stack from CloudFormation  [CloudFormation](https://console.aws.amazon.com/cloudformation/) with name ‘hdp-simple’ using the json template
  - 2. Execute ‘hdp-install.sh’ from the Ambari node. You will be prompted for your AWS credentials.


#### To be scripted for benchmark tools
```sudo yum groupinstall “Development Tools”```
