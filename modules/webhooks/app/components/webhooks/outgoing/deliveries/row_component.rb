module ::Webhooks
  module Outgoing
    module Deliveries
      class RowComponent < ::RowComponent
        property :id, :description, :event_name, :response_code

        def log
          model
        end

        def time
          model.updated_at.to_s # Force ISO8601
        end

        def response_body
          render ResponseComponent.new(log)
        end
      end
    end
  end
end
