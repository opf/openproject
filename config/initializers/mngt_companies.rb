# frozen_string_literal: true

module Mngt
  module Companies
    REGISTRY = {
      "grupomngt.com.br"    => { name: "CSC",              slug: "csc",          can_see_all: true  },
      "areaincrivel.com.br" => { name: "Área Incrível",    slug: "areaincrivel", can_see_all: false },
      "maisarmazem.com.br"  => { name: "Mais Armazém",     slug: "maisarmazem",  can_see_all: false },
      "clrc.com.br"         => { name: "Centro Logístico", slug: "clrc",         can_see_all: false },
    }.freeze

    # Maps API company names (from external people API) to Stream channel slugs.
    COMPANY_NAME_TO_SLUG = {
      "Grupo MNGT"    => "csc",
      "Área Incrível" => "areaincrivel",
      "Mais Armazém"  => "maisarmazem",
      "Lar Incrível"  => "larincrivel",
      "Galpões SA"    => "galpoessa",
    }.freeze

    # Strips accents, lowercases, removes non-alphanumeric chars for fuzzy matching.
    def self.normalize(str)
      str.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.gsub(/[^a-z0-9\s]/, "").squish
    end

    # Returns Stream slug for an API company name (fuzzy match).
    def self.slug_for_company_name(name)
      normalized = normalize(name)
      COMPANY_NAME_TO_SLUG.find { |k, _v| normalize(k) == normalized }&.last
    end

    def self.for_email(email)
      domain = email.to_s.split("@").last.to_s.downcase
      REGISTRY[domain]
    end

    def self.slug_for(email)
      for_email(email)&.fetch(:slug, nil) || "csc"
    end

    def self.display_name_for(email)
      for_email(email)&.fetch(:name, nil) || "CSC"
    end

    def self.can_see_all?(email)
      for_email(email).nil? || for_email(email).fetch(:can_see_all, false)
    end

    # { "csc" => "CSC", "areaincrivel" => "Área Incrível", ... }
    def self.slug_to_name
      REGISTRY.values.each_with_object({}) { |c, h| h[c[:slug]] = c[:name] }
    end

    # Returns the company slug embedded in a channel ID (e.g. "areaincrivel--geral" => "areaincrivel").
    def self.slug_from_channel_id(channel_id)
      channel_id.to_s.split("--").first
    end
  end
end
