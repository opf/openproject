module OpenProject::Storages
  module Admin
    # @hidden
    class OAuthAccessGrantNudgeModalComponentPreview < Lookbook::Preview
      # Renders an oauth access grant nudge modal component
      def default
        storage = FactoryBot.build_stubbed(:nextcloud_storage)
        render_with_template(locals: { storage:, confirm_button_url: "#" })
      end
    end
  end
end
