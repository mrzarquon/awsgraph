#!/bin/bash

PP_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PP_IMAGE_NAME=$(curl -s http://169.254.169.254/latest/meta-data/ami-id)

mkdir -p /opt/puppetlabs/puppet/cache/state/

echo "agent provision lock" > /opt/puppetlabs/puppet/cache/state/agent_disabled.lock

mkdir -p /etc/puppetlabs/puppet/

cat > /etc/puppetlabs/puppet/csr_attributes.yaml << YAML
extension_requests:
  pp_instance_id: $PP_INSTANCE_ID
  pp_image_name: $PP_IMAGE_NAME
  pp_role: 'web'
YAML

curl -k https://ip-10-90-30-108.ap-southeast-2.compute.internal:8140/packages/current/install.bash | /bin/bash -s agent:certname=$PP_INSTANCE_ID

/opt/puppetlabs/puppet/bin gem install --no-ri --no-rdoc retries aws-sdk-core

/opt/puppetlabs/bin/puppet --enable

/opt/puppetlabs/bin/puppet agent -t
