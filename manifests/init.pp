#example forge architecture
class awsgraph {
  $aws_tags = {
    'department' => 'tse',
    'created_by' => 'chrisbarker',
  }


  ec2_securitygroup { 'forge_frontend':
    ensure      => present,
    region      => 'ap-southeast-2',
    vpc         => 'tse-ap-southeast-2-vpc',
    description => 'Forge frontend',
    ingress     => [
      {
        protocol => 'tcp',
        port     => '80',
        cidr     => '0.0.0.0/0',
      },
      {
        protocol => 'tcp',
        port     => '443',
        cidr     => '0.0.0.0/0',
      },
    ],
    tags => $aws_tags,
  }

  ec2_securitygroup { 'forge_backend':
    ensure      => present,
    region      => 'ap-southeast-2',
    vpc         => 'tse-ap-southeast-2-vpc',
    description => 'Forge backend',
    ingress     => [
      {
        protocol => 'tcp',
        port     => '80',
        cidr     => '0.0.0.0/0',
      },
      {
        protocol => 'tcp',
        port     => '4430',
        cidr     => '0.0.0.0/0',
      },
      {
        protocol => 'tcp',
        port     => '443',
        cidr     => '0.0.0.0/0',
      },
    ],
    tags => $aws_tags,
  }

  elb_loadbalancer { 'frontend':
    ensure               => present,
    region               => 'ap-southeast-2',
    subnets              => ['tse-ap-southeast-2-avza', 'tse-ap-southeast-2-avzb'],
    instances            => ['web-frontend-01', 'web-frontend-02'],
    security_groups      => ['forge_frontend'],
    listeners            => [{
      protocol           => 'HTTP',
      load_balancer_port => 80,
      instance_protocol  => 'HTTP',
      instance_port      => 80,
    }],
    tags => $aws_tags,
  }

  elb_loadbalancer { 'backend':
    ensure               => present,
    region               => 'ap-southeast-2',
    subnets              => ['tse-ap-southeast-2-avza', 'tse-ap-southeast-2-avzb'],
    instances            => ['web-backend-01', 'web-backend-02'],
    security_groups      => ['forge_backend'],
    listeners            => [{
      protocol           => 'HTTP',
      load_balancer_port => 80,
      instance_protocol  => 'HTTP',
      instance_port      => 80,
    }],
    tags => $aws_tags,
  }

  Ec2_Instance {
    ensure            => 'running',
    image_id          => 'ami-fedafc9d',
    instance_type     => 't2.medium',
    key_name          => 'chrisbarker',
    region            => 'ap-southeast-2',
    iam_instance_profile_name => 'puppetlabs_aws_provisioner',
    security_groups   => [
      'tse-ap-southeast-2-crossconnect',
      'tse-ap-southeast-2-agents'],
    tags              => $aws_tags,
  }

  ec2_instance { 'web-frontend-01':
    availability_zone => 'ap-southeast-2a',
    subnet            => 'tse-ap-southeast-2-avza',
    require           => Elb_Loadbalancer['backend'],
    before            => Elb_Loadbalancer['frontend'],
    user_data         => 'puppet:///modules/awsgraph/web.sh',
  }
  ec2_instance { 'web-frontend-02':
    availability_zone => 'ap-southeast-2b',
    subnet            => 'tse-ap-southeast-2-avzb',
    require           => Elb_Loadbalancer['backend'],
    before            => Elb_Loadbalancer['frontend'],
    user_data         => 'puppet:///modules/awsgraph/web.sh',
  }
  ec2_instance { 'web-backend-01':
    availability_zone => 'ap-southeast-2a',
    subnet            => 'tse-ap-southeast-2-avza',
    before            => Elb_Loadbalancer['backend'],
    user_data         => 'puppet:///modules/awsgraph/db.sh',
  }
  ec2_instance { 'web-backend-02':
    availability_zone => 'ap-southeast-2b',
    subnet            => 'tse-ap-southeast-2-avzb',
    before            => Elb_Loadbalancer['backend'],
    user_data         => 'puppet:///modules/awsgraph/db.sh',
  }
}
