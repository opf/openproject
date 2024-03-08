module OpenProject::Storages
  module Admin
    # @hidden
    class OAuthAccessGrantNudgeModalComponentPreview < Lookbook::Preview
      # Renders a oauth access grant nudge modal component
      # @param authorized toggle Denotes whether access has been granted and renders a success state
      def default(authorized: false)
        project_storage = FactoryBot.build_stubbed(:project_storage)
        render_with_template(locals: { project_storage:, authorized:, confirm_button_url: "#" })
      end
    end
  end
end
