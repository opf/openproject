module OpenIDConnect
  module Providers
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      def provider
        model
      end

      def column_args(column)
        if column == :name
          { style: "grid-column: span 3" }
        else
          super
        end
      end

      def name
        link = render(
          Primer::Beta::Link.new(
            href: url_for(action: :edit, id: provider.id),
            font_weight: :bold,
            mr: 1
          )
        ) { provider.display_name }
        if !provider.configured?
          link.concat(
            render(Primer::Beta::Label.new(scheme: :attention)) { I18n.t(:label_incomplete) }
          )
        end
        link
      end

      def type
        I18n.t("openid_connect.providers.#{provider.oidc_provider}.name")
      end

      def row_css_class
        [
          "openid-connect--provider-row",
          "openid-connect--provider-row-#{model.id}"
        ].join(" ")
      end

      def button_links
        []
      end

      def users
        provider.user_count.to_s
      end

      def creator
        helpers.avatar(provider.creator, size: :mini, hide_name: false)
      end

      def created_at
        helpers.format_time provider.created_at
      end
    end
  end
end
