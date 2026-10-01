# frozen_string_literal: true

module ::Webhooks
  module Outgoing
    module Deliveries
      class ResponseComponent < ApplicationComponent
        property :id
        property :response_headers
        property :response_body

        def response_body_title
          model.class.human_attribute_name(:response_body)
        end
      end
    end
  end
end
