module AugurHelper
  def augur_content_security_policy
    controller.append_content_security_policy_directives(
      connect_src: %w(augur.openproject-edge.com)
    )
  end
end
