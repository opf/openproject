# frozen_string_literal: true

require "net/http"
require "json"

module Mngt
  class ExternalPeopleService
    Error = Class.new(StandardError)

    def self.all
      new.fetch_all
    end

    def self.companies
      new.fetch_companies
    end

    def self.bust_cache!
      Rails.cache.delete(Mngt::ExternalPeople::CACHE_KEY)
      Rails.cache.delete(Mngt::ExternalPeople::COMPANIES_CACHE_KEY)
    end

    def fetch_all
      Rails.cache.fetch(Mngt::ExternalPeople::CACHE_KEY, expires_in: Mngt::ExternalPeople::CACHE_TTL) do
        raw = fetch_json(Mngt::ExternalPeople::API_URL)
        extract_people(raw)
      end
    end

    def fetch_companies
      Rails.cache.fetch(Mngt::ExternalPeople::COMPANIES_CACHE_KEY, expires_in: Mngt::ExternalPeople::CACHE_TTL) do
        raw = fetch_json(Mngt::ExternalPeople::COMPANIES_API_URL)
        raw.is_a?(Array) ? raw : []
      end
    end

    private

    def fetch_json(url)
      uri     = URI(url)
      request = Net::HTTP::Get.new(uri)
      request["X-Integration-Token"] = Mngt::ExternalPeople.api_token
      request["Accept"]              = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port,
                                 use_ssl: true,
                                 open_timeout: 10,
                                 read_timeout: 30) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "HTTP #{response.code}: #{response.body.truncate(200)}"
      end

      JSON.parse(response.body)
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
