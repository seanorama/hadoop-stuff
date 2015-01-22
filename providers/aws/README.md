Deploy Hortonworks Data Platform on AWS with CloudFormation
====

--
![Here be dragons](http://skeptoid.com/blog/wp-content/uploads/2013/03/Briandunning-HereBeDragons229.jpg)

**Use at your own risk.**

I’ll update this note when the code is more _certified_.

And I'm not to blame for the costs associated with addictions to TBs of Hadoop _awesomeness_.

--

### Requires

 - AWS CloudFormation
 - Apache Ambari Blueprints
 - messy sh scripts

### Current status

  - CloudFormation builds a simple cluster with a single master node
  - Then you trigger the Ambari build manually.

### Usage

  - 1. Deploy a new stack from CloudFormation  [CloudFormation](https://console.aws.amazon.com/cloudformation/):
    - hdp-simple: with tons of attached storage
    - hdp-small: without attached storage
  - 2. Execute ‘hdp-install.sh’ from the Ambari node. You will be prompted for your AWS credentials.

### Extra

  - hdp-base will install the nodes without Ambari


-- 
Sean Roberts, @seano