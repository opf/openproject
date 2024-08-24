# frozen_string_literal: true

module OpenProject::Users
  # @logical_path OpenProject/Users
  class AvatarComponentPreview < Lookbook::Preview
    # Renders a user avatar using the OpenProject opce-principal web component
    # @param size select { choices: [default, medium, mini] }
    # @param link toggle
    # @param show_name toggle
    def default(size: :default, link: true, show_name: true)
      user = FactoryBot.build_stubbed(:user)
      render(Users::AvatarComponent.new(user:, size:, link:, show_name:))
    end

    def sizes
      user = FactoryBot.build_stubbed(:user)
      render_with_template(locals: { user: })
    end
  end
end
