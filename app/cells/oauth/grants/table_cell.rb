require_dependency 'oauth/grants/row_cell'

module OAuth
  module Grants
    class TableCell < ::TableCell

      class << self
        def row_class
          ::OAuth::Grants::RowCell
        end
      end

      def initial_sort
        %i[id asc]
      end

      def sortable?
        false
      end

      def columns
        headers.map(&:first)
      end

      def empty_row_message
        I18n.t 'oauth.grants.none_given'
      end

      def headers
        [
          ['created_at', caption: ActiveRecord::Base.human_attribute_name(:created_at) ],
          ['scopes', caption: ::Doorkeeper::Application.human_attribute_name(:scopes)]
        ]
      end
    end
  end
end
