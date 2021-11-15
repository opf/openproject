module OpenIDConnect
  module Providers
    class RowCell < ::RowCell
      include ::IconsHelper

      def provider
        model
      end

      def name
        link_to(
          provider.display_name || provider.name,
          url_for(action: :edit, id: provider.id)
        )
      end

      def row_css_class
        [
          'openid-connect--provider-row',
          "openid-connect--provider-row-#{model.id}"
        ].join(' ')
      end

      ###

      def button_links
        [edit_link, delete_link]
      end

      def edit_link
        link_to(
          op_icon('icon icon-edit button--link'),
          url_for(action: :edit, id: provider.id),
          title: t(:button_edit)
        )
      end

      def delete_link
        link_to(
          op_icon('icon icon-delete button--link'),
          url_for(action: :destroy, id: provider.id),
          method: :delete,
          data: { confirm: I18n.t(:text_are_you_sure) },
          title: t(:button_delete)
        )
      end
    end
  end
end
