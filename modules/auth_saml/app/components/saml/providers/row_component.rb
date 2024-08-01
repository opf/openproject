module Saml
  module Providers
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      def provider
        model
      end

      def name
        concat render(Primer::Beta::Link.new(
          scheme: :primary,
          href: url_for(action: :show, id: provider.id)
        )) { provider.display_name || provider.name }

        if provider.idp_sso_target_url
          concat render(Primer::Beta::Text.new(
            tag: :p,
            font_size: :small,
            color: :subtle
          )) { provider.idp_sso_target_url }
        end
      end

      def button_links
        [edit_link, delete_link].compact
      end

      def edit_link
        link_to(
          helpers.op_icon('icon icon-edit button--link'),
          url_for(action: :edit, id: provider.id),
          title: t(:button_edit)
        )
      end

      def users
        "1234"
      end

      def delete_link
        return if provider.readonly

        link_to(
          helpers.op_icon('icon icon-delete button--link'),
          url_for(action: :destroy, id: provider.id),
          method: :delete,
          data: { confirm: I18n.t(:text_are_you_sure) },
          title: t(:button_delete)
        )
      end
    end
  end
end
