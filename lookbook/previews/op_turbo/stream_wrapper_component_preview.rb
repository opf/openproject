# frozen_string_literal: true

module OpTurbo
  # @logical_path OpenProject/OpTurbo
  class StreamWrapperComponentPreview < Lookbook::Preview
    # Renders a turbo-stream tag with given action and target
    # @param action select { choices: [append, prepend, replace, update, remove, before, after] }
    # @param target text
    def default(action: 'append', target: 'model_id')
      template = template_example_from_action(action, target)
      render_with_template(locals: { template:, action:, target: })
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
