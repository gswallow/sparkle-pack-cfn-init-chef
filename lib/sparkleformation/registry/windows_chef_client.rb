SfnRegistry.register(:windows_chef_client) do |_name, _config={}|

  ENV['environment'] ||= '_default'

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
      sets.default += ['chef_client']
    end
    chef_client do

      ### NEW

      files("c:\\chef\\client.rb") do
        content join!(
                  "chef_server_url             \"", _config[:chef_server], "\"\n",
                  "environment                 \"", _config.fetch(:chef_environment, ENV['environment']), "\"\n",
                  "validation_client_name      \"", _config[:chef_validation_client], "\"\n",
                  "log_level                   :", _config.fetch(:chef_log_level, 'info').to_s, "\n",
                  "log_location                \"c:/chef/chef.log\"\n",
                  "file_cache_path             \"c:/chef/cache\"\n",
                  "cookbook_path               \"c:/chef/cache/cookbooks\"\n",
                  "enable_reporting_url_fatals ", _config.fetch(:chef_fail_on_reporting_errors, 'false'), "\n"
                )
      end

      files("c:\\chef\\first-run.json") do
        content first_run
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

      files("c:\\chef\\ohai\\hints\\ec2.json") do
        content "{}"
      end

      files("c:\\chef\\validation.pem") do
        source join!(
          'https://', _config[:chef_bucket] , '.s3.amazonaws.com/', 'validation.pem'
        )
        authentication 'ChefS3Auth'
      end

      if _config[:chef_data_bag_secret]
        files("c:\\chef\\encrypted_data_bag_secret") do
          source join!(
            'https://', _config[:chef_bucket], '.s3.amazonaws.com/', 'encrypted_data_bag_secret'
          )
          authentication 'ChefS3Auth'
        end
      end

      packages do
        msi do
          data![:awscli] = "https://s3.amazonaws.com/aws-cli/AWSCLI64.msi"
          data![:chef_client] = "https://packages.chef.io/stable/windows/2008r2/chef-client-12.4.0-1.msi"
        end
      end

      commands "00-run-chef-client" do
        command join!(
                  "SET \"PATH=%PATH%;c:\\ruby\\bin;c:\\opscode\\chef\\bin;c:\\opscode\\chef\\embedded\\bin\" &&",
                  " c:\\opscode\\chef\\bin\\chef-client -j c:\\chef\\first-run.json"
                )
        data![:waitAfterCompletion] = "0"
      end
    end
  end
end
