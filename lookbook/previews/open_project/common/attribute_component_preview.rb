module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class AttributeComponentPreview < Lookbook::Preview
      # @param id
      # @param name
      # @param description
      def default(id: 'attribute_modal', name: 'Description', description: '<figure>This button is only visible when the description is truncated or it includes a figure or macro</figure>')
        render OpenProject::Common::AttributeComponent.new(id, name, description)
      end
    end
  end
end
