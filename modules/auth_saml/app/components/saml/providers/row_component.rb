# frozen_string_literal: true

module Saml
  module Providers
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      def provider
        model
      end

      def name
        concat render(Primer::Beta::Link.new(
                        font_weight: :bold,
                        href: url_for(action: :show, id: provider.id)
                      )) { provider.display_name || provider.name }

        render_availability_label
      end

      def render_availability_label
        unless provider.available?
          render(Primer::Beta::Label.new(ml: 2, scheme: :attention, size: :medium)) { t(:label_incomplete) }
        end
      end

      def button_links
        [edit_link, delete_link].compact
      end

      def edit_link
        link_to(
          helpers.op_icon("icon icon-edit button--link"),
          url_for(action: :edit, id: provider.id),
          title: t(:button_edit)
        )
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

      def delete_link
        return if provider.readonly

        link_to(
          helpers.op_icon("icon icon-delete button--link"),
          url_for(action: :confirm_destroy, id: provider.id),
          data: { turbo_stream: true },
          title: t(:button_delete)
        )
      end
    end
  end
end
