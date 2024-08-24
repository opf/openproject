module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class AttributeComponentPreview < Lookbook::Preview
      # @param id
      # @param name
      # @param text
      def default(id: "attribute_modal",
                  name: "Description",
                  text: "<figure>This button is only visible when the text is truncated or includes a figure or macro.</figure>")
        render OpenProject::Common::AttributeComponent.new(id, name, text)
      end
    end
  end
end
