module OpPrimer
  # @logical_path OpenProject/Primer
  class BannerMessageComponentPreview < Lookbook::Preview
    def default
      render(OpPrimer::BannerMessageComponent.new) do
        I18n.t("notice_meeting_updated")
      end
    end

    def danger
      render(OpPrimer::BannerMessageComponent.new(scheme: :danger, icon: :stop)) do |_component|
        "Stop right there."
      end
    end

    def button
      render(OpPrimer::BannerMessageComponent.new) do |component|
        component.with_action_button(
          tag: :a,
          href: "/"
        ) { "Go home" }

        I18n.t("notice_meeting_updated")
      end
    end
  end
end
