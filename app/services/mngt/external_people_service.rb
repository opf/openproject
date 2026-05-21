# frozen_string_literal: true

require "net/http"
require "json"

module Mngt
  class ExternalPeopleService
    Error = Class.new(StandardError)

    def self.all
      new.fetch_all
    end

    def self.bust_cache!
      Rails.cache.delete(Mngt::ExternalPeople::CACHE_KEY)
    end

    def fetch_all
      Rails.cache.fetch(Mngt::ExternalPeople::CACHE_KEY, expires_in: Mngt::ExternalPeople::CACHE_TTL) do
        fetch_from_api
      end
    end

    private

    def fetch_from_api
      uri = URI(Mngt::ExternalPeople::API_URL)
      request = Net::HTTP::Get.new(uri)
      request["X-Integration-Token"] = Mngt::ExternalPeople.api_token
      request["Accept"]        = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port,
                                 use_ssl: true,
                                 open_timeout: 10,
                                 read_timeout: 30) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "HTTP #{response.code}: #{response.body.truncate(200)}"
      end

      raw = JSON.parse(response.body)
      extract_people(raw)
    rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout,
           Errno::ECONNREFUSED, SocketError => e
      raise Error, "External people API unreachable: #{e.message}"
    end

    def extract_people(raw)
      case raw
      when Array then raw
      when Hash  then raw["data"] || raw["people"] || raw["results"] || raw.values.first || []
      else []
      end
    end
  end
end
