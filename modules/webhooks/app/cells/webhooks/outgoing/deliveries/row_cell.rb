module ::Webhooks
  module Outgoing
    module Deliveries
      class RowCell < ::RowCell
        include ::IconsHelper

        def log
          model
        end

        def time
          model.updated_at.to_s # Force ISO8601
        end

        def response_body
          render(locals: { log_entry: log },
                 prefixes: ["#{::OpenProject::Webhooks::Engine.root}/app/cells/views"]).html_safe
        end
      end
    end
  end
end