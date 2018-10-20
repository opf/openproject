module CrowdinHelper
  def crowdin_in_context_translation
    return unless OpenProject::Configuration.crowdin_in_context_translations?
    return unless ::I18n.locale == :lol

    # Enable CSP to load the following script by whitelisting for this request.
    # This will be slower than manually adding it to the initializer, but we wouldn't want to
    # allow cdn.crowdin.com for users without in context translations.
    controller.append_content_security_policy_directives(
      # initial script and setup API calls
      script_src: %w(cdn.crowdin.com crowdin.com),
      # Form action to crowdin, github etc.
      form_action: %w[https://crowdin.com
                      https://accounts.google.com
                      https://api.twitter.com
                      https://github.com
                      https://gitlab.com],
      # Iframe
      frame_src: %w(crowdin.com),
      # CSS loaded from cdn
      style_src: %w(cdn.crowdin.com)
    )

    concat(nonced_javascript_tag do
      "var _jipt = []; _jipt.push(['project', 'openproject']);".html_safe
    end)
    concat javascript_include_tag 'https://cdn.crowdin.com/jipt/jipt.js'
  end
end
