SfnRegistry.register(:single_instance_user_data) do |_name, _config = {}|

  user_data base64!(
    join!(
      "#!/bin/bash\n\n",

      "# We are using resource signaling, rather than wait condition handles\n",
      "# http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-signal.html\n\n",

      "function my_instance_id\n",
      "{\n",
      "  curl -sL http://169.254.169.254/latest/meta-data/instance-id/\n",
      "}\n\n",

      "function cfn_signal_and_exit\n",
      "{\n",
      "  status=$?\n",
      "  /usr/local/bin/cfn-signal ",
      "   --role ", _config[:iam_role],
      "   --region ", region!,
      "   --resource ", "#{_name.capitalize}Ec2Instance",
      "   --stack ", stack_name!,
      "   --exit-code $status\n",
      "  exit $status\n",
      "}\n\n",

      "/usr/local/bin/cfn-init -s ", stack_name!, " --resource ", "#{_name.capitalize}Ec2Instance",
      "   --region ", region!, " || cfn_signal_and_exit\n\n",

      "cfn_signal_and_exit\n"
    )
  )
end