
#### DON'T TOUCH!!!
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"

#### Configuration
CONFD=${__dir}/config.d
MASTER_HOSTS=()
MASTER_HOSTS=($(<${CONFD}/masters.list))
WORKER_HOSTS=()
WORKER_HOSTS=($(<${CONFD}/workers.list))

AMBARI_SERVICES=(HDFS MAPREDUCE2 YARN TEZ SLIDER HIVE GANGLIA ZOOKEEPER)
AMBARI_HOST=${AMBARI_HOST:-localhost}
API_AMBARI_VERSION="1.7.0"
API_HDP_VERSION="2.2"

AMBARI_API="http://${AMBARI_HOST}:8080/api/v1"
AMBARI_CURL="curl -su admin:admin -H X-Requested-By:ambari"

#jq -n --arg hosts "$hosts" '{ hosts: $hosts | split("\n") }'
HOSTS_WORKERS_JSON=$(jq -n  --arg v "${WORKER_HOSTS[*]}" '$v | split(" ")')
AMBARI_SERVICES_JSON=$(jq -n  --arg v "${AMBARI_SERVICES[*]}" '$v | split(" ")')

echo $HOSTS_WORKERS_JSON

