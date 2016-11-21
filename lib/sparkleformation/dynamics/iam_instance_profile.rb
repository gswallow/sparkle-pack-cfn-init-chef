SparkleFormation.dynamic(:iam_instance_profile) do |_name, _config = {}|

  # Create an IAM Instance Profile, which basically binds together an IAM role allowing
  # privilege escalation, and list of actions to allow elevated access to.
  #
  # Default actions are:
  #
  # cloudformation:DescribeStackResource on the instance's stack
  # cloudformation:SignalResource on the instance's stack
  # autoscaling:SetInstanceHealth on any ec2 instance in the instance's region
  # s3:GetObject on anything in the Chef bucket
  #
  # Pass in a list of policy statements through _config[:policy_statements].

  _config[:policy_statements] ||= []

  dynamic!(:i_a_m_instance_profile, _name).properties do
    path '/'
    roles _array(
            ref!("#{_name}_i_a_m_role".to_sym)
          )
  end
  dynamic!(:i_a_m_instance_profile, _name).depends_on "#{_name.capitalize}IAMPolicy"

  dynamic!(:i_a_m_role, _name).properties do
    assume_role_policy_document do
      version '2012-10-17'
      statement _array(
        -> {
          effect 'Allow'
          principal do
            service _array( 'ec2.amazonaws.com' )
          end
          action _array( 'sts:AssumeRole' )
        }
      )
    end
    path '/'
  end


  # <shrug> http://docs.aws.amazon.com/autoscaling/latest/userguide/IAM.html#AutoScaling_ARN_Format
  dynamic!(:i_a_m_policy, _name).properties do
    policy_name 'chefValidatorKeyAccess'
    policy_document do
      version '2012-10-17'
      statement _array(
        *_config.fetch(:policy_statements, []).map { |s| s.is_a?(Hash) ? registry!(s.keys.first.to_sym, s.values.first) : registry!(s.to_sym) },
        -> {
          action %w(cloudformation:DescribeStackResource cloudformation:SignalResource)
          resource join!( join!('arn', 'aws', 'cloudformation', region!, account_id!, 'stack', :options => { :delimiter => ':'}), stack_name!, stack_id!, :options => { :delimiter => '/' })
          effect 'Allow'
        },
        -> {
          action %w(autoscaling:SetInstanceHealth)
          resource '*'
          effect 'Allow'
        },
        -> {
          action %w(s3:GetObject)
          resource join!( join!( 'arn', 'aws', 's3', '', '', _config[:chef_bucket], :options => { :delimiter => ':' }), '*', :options => { :delimiter => '/' })
          effect 'Allow'
        }
      )
    end
    roles _array( ref!("#{_name}_i_a_m_role".to_sym))
  end
  dynamic!(:i_a_m_policy, _name).depends_on "#{_name.capitalize}IAMRole"
end
