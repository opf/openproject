# frozen_string_literal: true

module OpPrimer
  # @logical_path OpenProject/Primer
  class CopyToClipboardComponentPreview < Lookbook::Preview
    # @param value text
    def default(value: "Copy me!")
      render(OpPrimer::CopyToClipboardComponent.new(value))
    end

    # @param url text
    def as_link(url: "http://example.org")
      render(OpPrimer::CopyToClipboardComponent.new(url, scheme: :link))
    end
  end
end
