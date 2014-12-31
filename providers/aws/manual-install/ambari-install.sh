#!/usr/bin/env bash
# Ambari installer
#
# This file:
#  - 
#  - 
#
# More info:
#  - 
#
#
# Authors:
#  - Sean Roberts (http://twitter.com/seano)
#
# Usage:
#  LOG_LEVEL=7 ./ambari-install.sh -f /tmp/x -d
#
# Licensed under MIT
# Copyright (c) 2015 Sean Roberts (http://twitter.com/seano)


### Configuration
#####################################################################

# Environment variables and their defaults
LOG_LEVEL="${LOG_LEVEL:-6}" # 7 = debug -> 0 = emergency

# Commandline options. This defines the usage page, and is used to parse cli
# opts & defaults from. The parsing is unforgiving so be precise in your syntax
read -r -d '' usage <<-'EOF'
  -r   [arg] (Required) Set an Ambari role to install. Valid: server, client
  -h   [arg] (Required) Hostname of the Ambari Server
  -t   [arg] Location of tempfile. Default="/tmp/bar"
  -d         Enables debug mode
  -h         This page
EOF

# Set magic variables for current FILE & DIR
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"


### Functions
#####################################################################

function _fmt ()      {
  local color_ok="\x1b[32m"
  local color_bad="\x1b[31m"

  local color="${color_bad}"
  if [ "${1}" = "debug" ] || [ "${1}" = "info" ] || [ "${1}" = "notice" ]; then
    color="${color_ok}"
  fi

  local color_reset="\x1b[0m"
  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then
    # Don't use colors on pipes or non-recognized terminals
    color=""; color_reset=""
  fi
  echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${color}$(printf "[%9s]" ${1})${color_reset}";
}
function emergency () {                             echo "$(_fmt emergency) ${@}" 1>&2 || true; exit 1; }
function alert ()     { [ "${LOG_LEVEL}" -ge 1 ] && echo "$(_fmt alert) ${@}" 1>&2 || true; }
function critical ()  { [ "${LOG_LEVEL}" -ge 2 ] && echo "$(_fmt critical) ${@}" 1>&2 || true; }
function error ()     { [ "${LOG_LEVEL}" -ge 3 ] && echo "$(_fmt error) ${@}" 1>&2 || true; }
function warning ()   { [ "${LOG_LEVEL}" -ge 4 ] && echo "$(_fmt warning) ${@}" 1>&2 || true; }
function notice ()    { [ "${LOG_LEVEL}" -ge 5 ] && echo "$(_fmt notice) ${@}" 1>&2 || true; }
function info ()      { [ "${LOG_LEVEL}" -ge 6 ] && echo "$(_fmt info) ${@}" 1>&2 || true; }
function debug ()     { [ "${LOG_LEVEL}" -ge 7 ] && echo "$(_fmt debug) ${@}" 1>&2 || true; }

function help () {
  echo "" 1>&2
  echo " ${@}" 1>&2
  echo "" 1>&2
  echo "  ${usage}" 1>&2
  echo "" 1>&2
  exit 1
}

function cleanup_before_exit () {
  info "Cleaning up. Done"
}
trap cleanup_before_exit EXIT


### Parse commandline options
#####################################################################

# Translate usage string -> getopts arguments, and set $arg_<flag> defaults
while read line; do
  opt="$(echo "${line}" |awk '{print $1}' |sed -e 's#^-##')"
  if ! echo "${line}" |egrep '\[.*\]' >/dev/null 2>&1; then
    init="0" # it's a flag. init with 0
  else
    opt="${opt}:" # add : if opt has arg
    init=""  # it has an arg. init with ""
  fi
  opts="${opts}${opt}"

  varname="arg_${opt:0:1}"
  if ! echo "${line}" |egrep '\. Default=' >/dev/null 2>&1; then
    eval "${varname}=\"${init}\""
  else
    match="$(echo "${line}" |sed 's#^.*Default=\(\)#\1#g')"
    eval "${varname}=\"${match}\""
  fi
done <<< "${usage}"

# Reset in case getopts has been used previously in the shell.
OPTIND=1

# Overwrite $arg_<flag> defaults with the actual CLI options
while getopts "${opts}" opt; do
  line="$(echo "${usage}" |grep "\-${opt}")"


  [ "${opt}" = "?" ] && help "Invalid use of script: ${@} "
  varname="arg_${opt:0:1}"
  default="${!varname}"

  value="${OPTARG}"
  if [ -z "${OPTARG}" ] && [ "${default}" = "0" ]; then
    value="1"
  fi

  eval "${varname}=\"${value}\""
  debug "cli arg ${varname} = ($default) -> ${!varname}"
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift


### Switches (like -d for debugmdoe, -h for showing helppage)
#####################################################################

# debug mode
if [ "${arg_d}" = "1" ]; then
  set -o xtrace
  LOG_LEVEL="7"
fi

# help mode
if [ "${arg_h}" = "1" ]; then
  # Help exists with code 1
  help "Help using ${0}"
fi


### Validation (decide what's required for running your script and error out)
#####################################################################

[ -z "${arg_r}" ]     && help      "Setting a install role (server or client) with -r is required."
[ -z "${arg_h}" ]     && help      "You must provide the hostname of the Ambari Server."
[ -z "${LOG_LEVEL}" ] && emergency "Cannot continue without LOG_LEVEL. "


### Runtime
#####################################################################

# Exit on error. Append ||true if you expect an error.
# set -e is safer than #!/bin/bash -e because that is neutralised if
# someone runs your script like `bash yourscript.sh`
set -o errexit
set -o nounset

# Bash will remember & return the highest exitcode in a chain of pipes.
# This way you can catch the error in case mysqldump fails in `mysqldump |gzip`
set -o pipefail

### Run it
##########

if [[ "$(python -mplatform)" != *"centos-6"* ]]; then
  error "This script is only tested with CentOS-6:"
  error "  - But you are using:" "$(python -mplatform)"
  exit
fi

if [[ "$(id -u)" -ne 0 ]]; then
  error "This script must be run as root or with sudo."
  exit
fi

cat <<-'EOF'
 We will install ambari-server & ambari-client

 First some prerequisites

EOF


echo # Disabling selinux
setenforce 0
sed -i 's/\(^[^#]*\)SELINUX=enforcing/\1SELINUX=disabled/' /etc/selinux/config
sed -i 's/\(^[^#]*\)SELINUX=permissive/\1SELINUX=disabled/' /etc/selinux/config

echo # disabling swap
echo 0 | tee /proc/sys/vm/swappiness
echo '' >> /etc/sysctl.conf
echo '#Set swappiness to 0 to avoid swapping' >> /etc/sysctl.conf
echo 'vm.swappiness = 0' >> /etc/sysctl.conf

echo # Disabling unnecessary services
chkconfig cups off || true
chkconfig postfix off || true
chkconfig iptables off || true
chkconfig ip6tables off || true

service iptables stop
service ip6tables stop

echo # enabling ntp
yum -y install ntp
chkconfig ntpd on
ntpd -q
service ntpd start

echo # installing java7
yum install -y java7-devel
export JAVA_HOME="/etc/alternatives/java_sdk"

echo # disabling transparent huge pages
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo no > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag 

echo '' >> /etc/rc.local
echo '#Disable THP' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/enabled; then' >> /etc/rc.local
echo '  echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
echo 'fi' >> /etc/rc.local
echo '' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/defrag; then' >> /etc/rc.local
echo '   echo never > /sys/kernel/mm/transparent_hugepage/defrag' >> /etc/rc.local
echo 'fi' >> /etc/rc.local
echo '' >> /etc/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/khugepaged/defrag; then' >> /etc/rc.local
echo '   echo no > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag' >> /etc/rc.local
echo 'fi' >> /etc/rc.local

echo # formatting ephemeral drives and mounting
sed '/^\/dev\/xvd[b-z]/d' -i /etc/fstab
for drv in `ls /dev/xv* | grep -v xvda`
do
  umount $drv || :
  mkdir -p ${drv//dev/data}
  echo "$drv ${drv//dev/data} ext4 defaults,noatime,nodiratime 0 0" >> /etc/fstab
  nohup mkfs.ext4 -m 0 -T largefile4 $drv &
done
wait

echo # resizing the root partition
(echo u;echo d; echo n; echo p; echo 1; cat /sys/block/xvda/xvda1/start; echo; echo w) | fdisk /dev/xvda || :


cat <<-'EOF'
 Now to install ambari-server & ambari-client packages

EOF


JAVA_HOME=/etc/alternatives/java_sdk
curl -o /etc/yum.repos.d/ambari.repo http://public-repo-1.hortonworks.com/ambari/centos6/1.x/updates/1.7.0/ambari.repo \
 || error 'Ambari repo setup failed'

if [[ "${arg_r}" == "server" ]]; then
  yum install -y ambari-server \
   || error 'Ambari Server Installation failed'
  ambari-server setup -j ${JAVA_HOME} -s \
   || error 'Ambari Server setup failed'
  ambari-server start \
   || error 'Ambari Server start-up failed'
fi

if [[ "${arg_r}" == "client" ]]; then
  yum install -y ambari-agent \
   || error 'Ambari Agent Installation failed'
  sed 's/^hostname=.*/hostname='"${arg_h}"'/' -i /etc/ambari-agent/conf/ambari-agent.ini
  ambari-agent start \
   || error 'Ambari Agent start-up failed'
fi


exit

##########

if [[ "${OSTYPE}" == "darwin"* ]]; then
  info "You are on OSX"
fi


debug "Info useful to developers for debugging the application, not useful during operations."
info "Normal operational messages - may be harvested for reporting, measuring throughput, etc. - no action required."
notice "Events that are unusual but not error conditions - might be summarized in an email to developers or admins to spot potential problems - no immediate action required."
warning "Warning messages, not an error, but indication that an error will occur if action is not taken, e.g. file system 85% full - each item must be resolved within a given time. This is a debug message"
error "Non-urgent failures, these should be relayed to developers or admins; each item must be resolved within a given time."
critical "Should be corrected immediately, but indicates failure in a primary system, an example is a loss of a backup ISP connection."
alert "Should be corrected immediately, therefore notify staff who can fix the problem. An example would be the loss of a primary ISP connection."
emergency "A \"panic\" condition usually affecting multiple apps/servers/sites. At this level it would usually notify all tech staff on call."


