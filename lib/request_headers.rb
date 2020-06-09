class CustomHeadersHelper
  cattr_accessor :headers
end

class RequestHeaders
  def initialize(app, helper = nil)
    @app, @helper = app, helper
  end

  def call(env)
    if @helper
      headers = @helper.headers

      if headers.is_a?(Hash)
        headers.each do |k,v|
          env["HTTP_#{k.upcase.gsub("-", "_")}"] = v
        end
      end
    end

    @app.call(env)
  end
end