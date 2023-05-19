module ::Webhooks
  module Outgoing
    module Deliveries
      class ResponseComponent < RailsComponent
        property :id
        property :response_headers
        property :response_body

        def title
          model.class.human_attribute_name('response_body')
        end
      end
    end
  end
end
