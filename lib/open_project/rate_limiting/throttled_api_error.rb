module OpenProject::RateLimiting
  class ThrottledApiError < ::API::Errors::ErrorBase
    identifier "Throttled"
    code 429

    def initialize(*)
      super("You have reached the request limit for this resource.")
    end
  end
end
