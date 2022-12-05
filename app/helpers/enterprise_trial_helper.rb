module EnterpriseTrialHelper
  def chargebee_content_security_policy
    script_src = %w(js.chargebee.com)
    default_src = script_src + ["#{OpenProject::Configuration.enterprise_chargebee_site}.chargebee.com"]

    append_content_security_policy_directives(
      script_src:,
      style_src: default_src,
      frame_src: default_src
    )
  end

  def youtube_content_security_policy
    append_content_security_policy_directives(
      frame_src: %w(https://www.youtube.com)
    )
  end
end
