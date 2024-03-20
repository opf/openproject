# frozen_string_literal: true

module OpTurbo
  # @logical_path OpenProject/OpTurbo
  class StreamComponentPreview < Lookbook::Preview
    # Renders a turbo-stream tag with given action and target
    # @param _action select { choices: [append, prepend, replace, update, remove, before, after] }
    # @param target text
    def default(_action: "append", target: "model_id")
      template = template_example_from_action(_action, target)
      render_with_template(locals: { template:, action: _action, target: })
    end

    private

    def template_example_from_action(action, target)
      <<~HTML
        <div id="#{target}">
          This div will #{action} to the element with the DOM ID "#{target}".
        </div>
      HTML
    end
  end
end
