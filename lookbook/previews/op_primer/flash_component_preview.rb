module OpPrimer
  # @logical_path OpenProject/Primer
  class FlashComponentPreview < Lookbook::Preview
    def default
      render(OpPrimer::FlashComponent.new) do
        I18n.t("notice_meeting_updated")
      end
    end

    def danger
      render(OpPrimer::FlashComponent.new(scheme: :danger, icon: :stop)) do |_component|
        "Stop right there."
      end
    end

    def unique_key
      render(OpPrimer::FlashComponent.new(unique_key: "bla", scheme: :danger, icon: :stop)) do |_component|
        "Stop right there."
      end
    end

    def button
      render(OpPrimer::FlashComponent.new) do |component|
        component.with_action_button(
          tag: :a,
          href: "/"
        ) { "Go home" }

        I18n.t("notice_meeting_updated")
      end
    end
  end
end
