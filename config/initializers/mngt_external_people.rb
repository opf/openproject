# frozen_string_literal: true

module Mngt
  module ExternalPeople
    API_URL   = "https://api.grupomngt.com.br/integration/people"
    CACHE_KEY = "mngt_external_people_v1"
    CACHE_TTL = 30.minutes

    def self.api_token
      ENV.fetch("MNGT_PEOPLE_API_TOKEN", "")
    end
  end
end
