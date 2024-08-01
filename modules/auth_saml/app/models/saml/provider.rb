module Saml
  class Provider < ApplicationRecord
    self.table_name = "saml_providers"

    belongs_to :creator, class_name: "User"

    store_attribute :options, :sp_entity_id, :string
    store_attribute :options, :name_identifier_format, :string
    store_attribute :options, :metadata_url, :string
    store_attribute :options, :metadata_xml, :string

    store_attribute :options, :mapping_login, :json
    store_attribute :options, :mapping_mail, :json
    store_attribute :options, :mapping_firstname, :json
    store_attribute :options, :mapping_lastname, :json
    store_attribute :options, :mapping_uid, :json

    store_attribute :options, :request_attributes, :json

    attr_accessor :readonly
    validates_presence_of :display_name

    def slug
      "saml-#{id}"
    end

    def assertion_consumer_service_url
      URI.join(url_helpers.root_url, "/auth/#{name}/callback").to_s
    end

    def limit_self_registration?
      limit_self_registration
    end

    def to_h
      options
        .merge(
          name: slug,
          display_name:,
          assertion_consumer_service_url:,
        )
    end

    private

  end
end
