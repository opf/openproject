module OpenIDConnect
  module Providers
    class TableCell < ::TableCell
      columns :name

      def initial_sort
        [:id, :asc]
      end

      def sortable?
        false
      end

      def empty_row_message
        I18n.t 'openid_connect.providers.no_results_table'
      end

      def headers
        [
          ['name', caption: I18n.t('attributes.name')]
        ]
      end
    end
  end
end
