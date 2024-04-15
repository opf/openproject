module AdditionalUrlHelpers
  include AuthenticationStagePathHelper

  module_function

  def fixed_home_url
    home_url(script_name: OpenProject::Configuration.rails_relative_url_root)
  end

  def configurable_home_url
    Setting.home_url.presence || fixed_home_url
  end

  def add_params_to_uri(uri, args = {})
    uri = URI.parse uri
    query = URI.decode_www_form String(uri.query)

    args.each do |k, v|
      query << [k, v]
    end

    uri.query = URI.encode_www_form query
    uri.to_s
  end
end
