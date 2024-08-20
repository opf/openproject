module ::Webhooks
  module Outgoing
    module Deliveries
      class RowComponent < ::RowComponent
        property :id, :description, :event_name

        def log
          model
        end

        def time
          model.updated_at.to_s # Force ISO8601
        end

        def response_code
          if log.response_code <= 0
            I18n.t(:label_none_parentheses)
          else
            log.response_code
          end
        end

        def response_body
          render ResponseComponent.new(log)
        end
      end
    end
  end
end
