# frozen_string_literal: true

# Proxies /assets/frontend/* to the Angular dev server running internally
# (e.g. http://frontend:4200 inside Docker). Used when CLI_PROXY and the app
# share the same origin (ngrok tunnel), which would cause a redirect loop with
# the default 307 redirect route.
#
# Activated by OPENPROJECT_DEV_ASSET_INTERNAL_HOST.
class FrontendAssetProxyController < ActionController::Metal
  INTERNAL_HOST = ENV.fetch("OPENPROJECT_DEV_ASSET_INTERNAL_HOST", nil)

  def proxy
    uri    = URI("#{INTERNAL_HOST}/assets/frontend/#{params[:appendix]}")
    result = Net::HTTP.get_response(uri)

    self.status        = result.code.to_i
    self.content_type  = result["content-type"].presence || "application/octet-stream"
    headers["Cache-Control"] = result["cache-control"] if result["cache-control"]
    self.response_body = result.body
  rescue StandardError => e
    self.status        = 502
    self.content_type  = "text/plain"
    self.response_body = "Asset proxy error: #{e.message}"
  end
end
