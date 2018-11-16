module ::Webhooks
  module Outgoing
    module Deliveries
      class TableCell < ::TableCell
        columns :id, :event_name, :time, :response_code, :response_body

        def sortable?
          false
        end

        def empty_row_message
          I18n.t 'webhooks.outgoing.deliveries.no_results_table'
        end

        def headers
          [
              ['id', caption: I18n.t('attributes.id')],
              ['event_name', caption: ::Webhooks::Log.human_attribute_name('event_name')],
              ['time', caption: I18n.t('webhooks.outgoing.deliveries.time')],
              ['response_code', caption: ::Webhooks::Log.human_attribute_name('response_code')],
              ['response_body', caption: ::Webhooks::Log.human_attribute_name('response_body')],
          ]
        end
      end
    end
  end
end
