require_dependency 'oauth/applications/row_cell'

module OAuth
  module Applications
    class TableCell < ::TableCell


      class << self
        def row_class
          ::OAuth::Applications::RowCell
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

      def inline_create_link
        link_to new_oauth_application_path,
                aria: { label: t('oauth.application.new') },
                class: 'wp-inline-create--add-link',
                title: t('oauth.application.new') do
          op_icon('icon icon-add')
        end
      end

      def empty_row_message
        I18n.t :no_results_title_text
      end

      def headers
        [
          ['name', caption: ::Doorkeeper::Application.human_attribute_name(:name)],
          ['owner', caption: ::Doorkeeper::Application.human_attribute_name(:owner)],
          ['client_credentials', caption: I18n.t('oauth.client_credentials')],
          ['redirect_uri', caption: ::Doorkeeper::Application.human_attribute_name(:redirect_uri)],
          ['confidential', caption: ::Doorkeeper::Application.human_attribute_name(:confidential)],
        ]
      end
    end
  end
end
