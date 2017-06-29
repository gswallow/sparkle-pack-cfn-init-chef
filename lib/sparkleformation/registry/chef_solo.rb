SfnRegistry.register(:chef_solo) do |_name, _config={}|

  ENV['environment'] ||= '_default'

  solo_rb = {
    'cookbook_path' => _config.fetch(:cookbook_path, [ '/var/chef/cache/cookbooks' ]),
    'data_bag_path' => _config.fetch(:data_bag_path, '/var/chef/cache/data_bags'),
    'log_level' => _config.fetch(:log_level, :info),
    'log_location' => _config.fetch(:log_location, '/var/log/chef/solo.log'),
    'role_path' => _config.fetch(:role_path, '/var/chef/cache/roles'),
    'solo' => 'true'
  }

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
      if _config.has_key?(:chef_data_bag_secret)
        files('/etc/chef/encrypted_data_bag_secret') do
          source join!(
            'https://', _config[:chef_bucket], '.s3.amazonaws.com/', 'encrypted_data_bag_secret'
          )
          mode '000400'
          owner 'root'
          group 'root'
          authentication 'ChefS3Auth'
        end
      end

      files('/etc/chef/solo.rb') do
        content join!(
                  solo_rb.map do |k, v|
                    if v.is_a?(String)
                      puts "#{k} \"#{v}\"\n"
                    else
                      puts "#{k} #{v.inspect}\n"
                    end
                  end
                )
        mode '000400'
        owner 'root'
        group 'root'
      end

      files('/etc/chef/node.json') do
        content first_run
      end

      if _config.has_key?(:cookbook_tarball)
        files('/var/chef/cache/cookbooks.tar.gz') do
          source join!(
            'https://', _config[:chef_bucket], '.s3.amazon.com/', '/', _config[:cookbook_tarball]
          )
          mode '000600'
          owner 'root'
          group 'root'
          authentication 'ChefS3Auth'
        end

        commands('00_extract_cookbooks') do
          command 'tar xzf /var/chef/cache/cookbooks.tar.gz -C /var/chef/cache/cookbooks'
          data![:ignoreErrors] = "true"
        end
      end

      commands('01_install_chef') do
        command join!('curl -sSL https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ', _config.fetch(:chef_version, 'latest'))
      end

      commands('02_log_dir') do
        command 'mkdir /var/log/chef'
        test 'test ! -e /var/log/chef'
      end

      commands('03_create_ec2_hints_file') do
        command 'mkdir -p /etc/chef/ohai/hints && touch /etc/chef/ohai/hints/ec2.json'
        test 'test ! -e /etc/chef/ohai/hints/ec2.json'
      end

      commands('04_run_chef_solo') do
        command 'chef-solo -c /etc/chef/solo.rb -j /etc/chef/node.json'
      end
    end
  end
end
