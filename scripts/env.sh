DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

os=$(uname)
if [ "${os}" == 'Darwin' ];then
  # Most likely this will be your wifi interface, though maybe this will break
  export IP_ADDRESS=$(ipconfig getifaddr en0)
elif [ "${os}" == 'Linux' ];then
  # This should pull out the default route interface and use it
  export IP_ADDRESS=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
fi

# This is for the time to wait when using demo_magic.sh
if [[ -z ${DEMO_WAIT} ]];then
  DEMO_WAIT=0
fi

# Demo magic gives wrappers for running commands in demo mode.   Also good for learning via CLI.

. ${DIR}/demo-magic.sh -d -p -w ${DEMO_WAIT}

# I store by vault env here, but most people probably don't have it
. ~/.vault_env &> /dev/null

