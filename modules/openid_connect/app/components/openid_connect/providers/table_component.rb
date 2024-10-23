module OpenIDConnect
  module Providers
    class TableComponent < ::OpPrimer::BorderBoxTableComponent
      columns :name, :type, :users, :creator, :created_at

      def initial_sort
        %i[id asc]
      end

      def header_args(column)
        if column == :name
          { style: "grid-column: span 3" }
        else
          super
        end
      end

      def has_actions?
        false
      end

      def sortable?
        false
      end

      def empty_row_message
        I18n.t "openid_connect.providers.no_results_table"
      end

      def headers
        [
          [:name, { caption: I18n.t("attributes.name") }],
          [:type, { caption: I18n.t("attributes.type") }],
          [:users, { caption: I18n.t(:label_user_plural) }],
          [:creator, { caption: I18n.t("js.label_created_by") }],
          [:created_at, { caption: OpenIDConnect::Provider.human_attribute_name(:created_at) }]
        ]
      end

      def blank_title
        I18n.t("openid_connect.providers.label_empty_title")
      end

      def blank_description
        I18n.t("openid_connect.providers.label_empty_description")
      end

      def row_class
        ::OpenIDConnect::Providers::RowComponent
      end

      def blank_icon
        :key
      end
    end
  end
end
