SfnRegistry.register(:windows_chef_solo) do |_name, _config={}|

  ENV['environment'] ||= '_default'

  solo_rb = {
    'cookbook_path' => _config.fetch(:cookbook_path, [ 'c:/chef/cookbooks' ]),
    'data_bag_path' => _config.fetch(:data_bag_path, 'c:/chef/data_bags'),
    'log_level' => _config.fetch(:log_level, :info),
    'log_location' => _config.fetch(:log_location, 'c:/chef/solo.log'),
    'role_path' => _config.fetch(:role_path, 'c:/chef/roles'),
    'solo' => 'true'
  }
#    'environment' => _config.fetch(:environment, ENV['environment']),
#    'environment_path' => _config.fetch(:environment_path, 'c:/chef/environments'),

  if _config.has_key?(:recipe_url)
    solo_rb['recipe_url'] = _config[:recipe_url]
  end

  first_run = _config.fetch(:chef_attributes, {}).merge(
    :stack => {
      :name => stack_name!,
      :id => stack_id!,
      :region => region!
    },
    :run_list => _config.fetch(:chef_run_list, [])
  )

  metadata('AWS::CloudFormation::Authentication') do
    chef_s3_auth do
      set!('roleName'._no_hump, _config[:iam_role])
      set!('buckets'._no_hump, [ _config[:chef_bucket] ])
      set!('type'._no_hump, 'S3')
    end
  end

  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    configSets do |sets|
      sets.default += ['chef_solo']
    end
    chef_solo do

      files("c:\\chef\\solo.rb") do
        content join!(
                  solo_rb.map do |k, v|
                    if v.is_a?(String)
                      puts "#{k} \"#{v}\"\n"
                    else
                      puts "#{k} #{v.inspect}\n"
                    end
                  end
                )
      end

      files("c:\\chef\\node.json") do
        content first_run
      end

      files("c:\\chef\\ohai\\hints\\ec2.json") do
        content "{}"
      end

      files("c:\\chef\\s3get.ps1") do
        content join!(
                  "param(\n",
                  "  [String] $bucketName,\n",
                  "  [String] $key,\n",
                  "  [String] $file\n",
                  ")\n\n",

                  "Import-Module \"c:\\program files (x86)\\aws tools\\powershell\\awspowershell\\awspowershell.psd1\"\n",
                  "Read-S3Object -BucketName $bucketName -Key $key -File $file\n"
                )
      end

      if _config[:chef_data_bag_secret]
        files("c:\\chef\\encrypted_data_bag_secret") do
          source join!(
            'https://', _config[:chef_bucket], '.s3.amazonaws.com/', 'encrypted_data_bag_secret'
          )
          authentication 'ChefS3Auth'
        end
      end

      if _config[:cookbook_tarball]
        files('c:\\chef\\cookbooks.tar.gz') do
          source join!(
            'https://', _config[:chef_bucket], '.s3.amazonaws.com', '/', _config[:cookbook_tarball]
          )
          authentication 'ChefS3Auth'
        end
      end

      packages do
        msi do
          data![:awscli] = "https://s3.amazonaws.com/aws-cli/AWSCLI64.msi"
          data![:chef_client] = "https://packages.chef.io/files/stable/chef/13.1.31/windows/2012/chef-client-13.1.31-1-x64.msi"
        end
      end

      if _config[:cookbook_tarball]
        commands "00-extract-cookbooks" do
          command join!(
                    "SET \"PATH=%PATH%;c:\\ruby\\bin;c:\\opscode\\chef\\bin;c:\\opscode\\chef\\embedded\\bin\" &&",
                    " c:\\opscode\\chef\\bin\\tar xvf c:\\chef\\cookbooks.tar.gz -C c:\\chef"
                    )
          data![:waitAfterCompletion] = "0"
          data![:ignoreErrors] = "true"
        end
      end

      commands "01-run-chef-solo" do
        command join!(
                  "SET \"PATH=%PATH%;c:\\ruby\\bin;c:\\opscode\\chef\\bin;c:\\opscode\\chef\\embedded\\bin\" &&",
                  " c:\\opscode\\chef\\bin\\chef-solo -j c:\\chef\\node.json -c c:\\chef\\solo.rb"
                )
        data![:waitAfterCompletion] = "0"
      end
    end
  end
end
