SparkleFormation.component(:chef_base) do

  ENV['chef_server']    ||= "https://api.opscode.com/organizations/#{ENV['chef_org']}"
  ENV['chef_validator'] ||= "#{ENV['chef_org']}-validator"
  ENV['chef_version']   ||= 'latest'

  parameters(:chef_server) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default ENV['chef_server']
  end

  parameters(:chef_validation_client_name) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default ENV['chef_validator']
    description 'Chef validation client name; see https://docs.chef.io/chef_private_keys.html'
    constraint_description 'can only contain ASCII characters'
  end

  parameters(:chef_version) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    default ENV['chef_version']
  end
end
