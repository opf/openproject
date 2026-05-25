# frozen_string_literal: true

module Mngt
  module Companies
    # All known companies, keyed by slug. Single source of truth.
    COMPANIES = {
      "csc"          => { name: "Grupo MNGT",   domain: "grupomngt.com.br",    can_see_all: true  },
      "areaincrivel" => { name: "Área Incrível", domain: "areaincrivel.com.br", can_see_all: false },
      "maisarmazem"  => { name: "Mais Armazém",  domain: "maisarmazem.com.br",  can_see_all: false },
      "larincrivel"  => { name: "Lar Incrível",  domain: nil,                   can_see_all: false },
      "galpoessa"    => { name: "Galpões SA",     domain: nil,                   can_see_all: false },
    }.freeze

    # Maps API company names (from external people API) to slugs.
    COMPANY_NAME_TO_SLUG = {
      "Grupo MNGT"    => "csc",
      "Área Incrível" => "areaincrivel",
      "Mais Armazém"  => "maisarmazem",
      "Lar Incrível"  => "larincrivel",
      "Galpões SA"    => "galpoessa",
    }.freeze

    # Derived: domain → slug for email-based lookup.
    DOMAIN_TO_SLUG = COMPANIES.each_with_object({}) { |(slug, c), h|
      h[c[:domain]] = slug if c[:domain]
    }.freeze

    # Strips accents, lowercases, removes non-alphanumeric chars for fuzzy matching.
    def self.normalize(str)
      str.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.gsub(/[^a-z0-9\s]/, "").squish
    end

    # Returns slug for an API company name (fuzzy match).
    def self.slug_for_company_name(name)
      normalized = normalize(name)
      COMPANY_NAME_TO_SLUG.find { |k, _v| normalize(k) == normalized }&.last
    end

    def self.for_email(email)
      domain = email.to_s.split("@").last.to_s.downcase
      slug   = DOMAIN_TO_SLUG[domain]
      return nil unless slug

      c = COMPANIES[slug]
      { name: c[:name], slug:, can_see_all: c[:can_see_all] }
    end

    def self.slug_for(email)
      for_email(email)&.fetch(:slug, nil) || "csc"
    end

    def self.display_name_for(email)
      for_email(email)&.fetch(:name, nil) || "Grupo MNGT"
    end

    # Unknown domain defaults to can_see_all: true (backward-compatible: grupomngt users
    # may authenticate via SSO with any email variant).
    def self.can_see_all?(email)
      for_email(email).nil? || for_email(email).fetch(:can_see_all, false)
    end

    def self.can_see_all_by_slug?(slug)
      COMPANIES.dig(slug.to_s, :can_see_all) || false
    end

    # The slug whose members have cross-company visibility (Grupo MNGT).
    def self.can_see_all_slug
      COMPANIES.find { |_s, c| c[:can_see_all] }&.first
    end

    # { "csc" => "Grupo MNGT", "areaincrivel" => "Área Incrível", ... }
    def self.slug_to_name
      COMPANIES.transform_values { |c| c[:name] }
    end

    # Returns the company slug embedded in a channel ID (e.g. "areaincrivel--geral" => "areaincrivel").
    def self.slug_from_channel_id(channel_id)
      channel_id.to_s.split("--").first
    end
  end
end
