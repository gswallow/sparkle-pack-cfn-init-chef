# sparkle-pack-cfn-init-chef
CFN Init Registry to bootstrap an instance with Chef

## iam_instance_profile dynamic

Creates an IAM instance profile allowing the resource to fetch objects from the Chef bucket, mark itself unhealthy if bootstrapping fails, so that its parent auto 
scaling group can terminate and try launching a replacement Chef node, and signal CloudFormation to satisfy a stack creation policy if bootstrapping succeeds.

The creation policy specifies that CloudFormation must get as many success notifications as the desired capacity in an auto scaling group.

_config[:policy_statements] = an array of hashes or symbols.  These objects will be passed to the SparkleFormation's registry! function, as a name, options pair
in the case of a hash, or individually in the case of a symbol.  Basically, create a policy statement as a registry, and pass it in as "extra" policy 
statements to attach to the IAM instance policy you're creating (i.e. modifying route53 entries).

## user_data registry

| Parameter | Purpose |
|-----------|---------|
| _config[:iam_role] | ref!(:your_iam_role) |
| _config[:resource_id] | The logical name of your auto scaling group, as it appears in the compiled JSON template |
| _config[:launch_config] | The logical name of your launch configuration, as it appears in the compiled JSON template |

## chef_client registry

| Parameter | Purpose |
|-----------|---------|
| _config[:chef_attributes] | Hash of Chef attributes |
| _config[:chef_run_list] | Array of Chef run list items |
| _config[:chef_bucket] | Chef bucket name (see https://github.com/gswallow/sparkle-pack-aws-my-s3-buckets) |
| _config[:chef_environment] | ENV['environment'] by default |
| _config[:chef_log_level] | :info by default |
| _config[:chef_validation_client] | the validation client name |
| _config[:chef_fail_on_reporting_errors] | false by default |
| _config[:chef_version] | 'latest' by default |
| _config[:iam_role] | ref!(:your_iam_role) |

## chef_solo registry

| Parameter | Purpose | Default Value |
|-----------|---------|---------------|
| _config[:cookbook_path] | List of chef cookbook paths | [ '/var/chef/cache/cookbooks' ] |
| _config[:data_bag_path] | Path to Chef data bags | /var/chef/cache/data_bags |
| _config[:log_level] | Chef log verbosity | :info |
| _config[:recipe_url] | The URL of a Chef cookbooks tarball file | none (must be an http/https/ftp URL) |
| _config[:role_path] | Path to chef roles | /var/chef/cache/roles |
| _config[:chef_attributes | A hash of Chef attributes to pass to chef-solo | Empty |
| _config[:chef_run_list ] | An array of Chef run list items | Empty |
| _config[:iam_role] | ref!(:your_iam_role) | |
| _config[:chef_bucket] | Chef bucket name (see https://github.com/gswallow/sparkle-pack-aws-my-s3-buckets) | |
| _config[:chef_data_bag_secret' | Set this parameter to grab an encrypted data bag secret from the Chef S3 bucket | Unset |
| _config[:cookbook_tarball] | Path of a tarball containing Chef cookbooks, in the Chef S3 bucket | Unset | 
| _config[:chef_version] | 'latest' by default |

## windows_chef_client registry

Same as the chef_client registry.

## windows_chef_solo registry

Same as the chef_solo registry.

