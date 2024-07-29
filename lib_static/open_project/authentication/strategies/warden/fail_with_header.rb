module OpenProject
  module Authentication
    module Strategies
      module Warden
        module FailWithHeader
          def fail_with_header!(error:, error_description: nil)
            headers(
              "WWW-Authenticate" => OpenProject::Authentication::WWWAuthenticate.response_header(
                default_auth_scheme: "Bearer",
                error:,
                error_description:
              )
            )
            fail!(error)
          end
        end
      end
    end
  end
end
