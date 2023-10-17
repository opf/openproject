# frozen_string_literal: true

module OpTurbo
  # @logical_path OpenProject/OpTurbo
  class FrameComponentPreview < Lookbook::Preview
    # Renders a turbo-frame tag with a unique id
    # @param context text
    def default(context: nil)
      model = FactoryBot.build_stubbed(:user)
      render_with_template(locals: { model:, context: })
    end
  end
end
