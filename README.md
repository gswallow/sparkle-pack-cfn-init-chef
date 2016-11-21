# sparkle-pack-cfn-init-chef
CFN Init Registry to bootstrap an instance with Chef

## iam_instance_profile dynamic

Creates an IAM instance profile allowing the resource to fetch objects from the Chef bucket, mark itself unhealthy so that its parent auto scaling group can
terminate and try launching a replacement Chef node, and signal CloudFormation to satisfy a stack creation policy.

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

You can pass ref!(...) objects or strings, mostly.

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
