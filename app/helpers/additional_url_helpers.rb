module AdditionalUrlHelpers
  include AuthenticationStagePathHelper

  module_function

  def add_params_to_uri(uri, args = {})
    uri =  URI.parse uri
    query = URI.decode_www_form String(uri.query)

    args.each do |k, v|
      query << [k, v]
    end

    uri.query = URI.encode_www_form query
    uri.to_s
  end
end
