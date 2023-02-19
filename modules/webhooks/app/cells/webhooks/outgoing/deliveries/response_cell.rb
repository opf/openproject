module ::Webhooks
  module Outgoing
    module Deliveries
      class ResponseCell < RailsCell
        view_paths << ::OpenProject::Webhooks::Engine.root.join("app/cells")

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
