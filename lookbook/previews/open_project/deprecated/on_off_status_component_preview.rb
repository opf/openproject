module OpenProject
  module Deprecated
    # @logical_path OpenProject/deprecated
    # @label On-Off status
    class OnOffStatusComponentPreview < Lookbook::Preview
      def default
        render ::Components::OnOffStatusComponent.new({
                                                        is_on: true,
                                                        on_text: "Is enabled",
                                                        on_description: "Text when enabled",
                                                        off_text: "Is disabled",
                                                        off_description: "Text when disabled"
                                                      })
      end

      def off
        render ::Components::OnOffStatusComponent.new({
                                                        is_on: false,
                                                        on_text: "Is enabled",
                                                        on_description: "Text when enabled",
                                                        off_text: "Is disabled",
                                                        off_description: "Text when disabled"
                                                      })
      end
    end
  end
end
