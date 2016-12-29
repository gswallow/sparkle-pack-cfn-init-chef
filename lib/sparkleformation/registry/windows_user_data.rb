SfnRegistry.register(:windows_user_data) do |_name, _config={}|

  user_data base64!(
    join!(
      "<script>\n",

      %Q!powershell.exe -ExecutionPolicy Unrestricted -NoProfile -NonInteractive "invoke-restmethod -uri http://169.254.169.254/latest/meta-data/instance-id/ | new-item instance-id.txt -itemtype file"\n!,
      %Q!for /f "delims=" %%x in (instance-id.txt) do set INSTANCE_ID=%%x\n\n!,

      "cfn-init.exe -v -s ", stack_name!, " --resource ", _config[:launch_config],
      " --region ", region!, "\n\n",

      "if ERRORLEVEL 1 (\n",
      %Q!  "%PROGRAMFILES%\\Amazon\\AWSCLI\\AWS.exe" autoscaling set-instance-health --instance-id %INSTANCE_ID% --health-status Unhealthy --region !, region!, "\n",
      ") else (\n",
      "  cfn-signal.exe",
      " --role ", _config[:iam_role],
      " --region ", region!,
      " --resource ", _config[:resource_id],
      " --stack ", stack_name!,
      " --exit-code %ERRORLEVEL%\n",
      ")\n",
      "</script>\n"
    )
  )
end
