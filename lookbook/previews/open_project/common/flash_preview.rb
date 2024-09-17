module OpenProject
  module Common
    # @hidden
    class FlashPreview < Lookbook::Preview
      def default
        render(Meetings::UpdateFlashComponent.new(
                 button_path_object: @meeting,
                 message: I18n.t("notice_meeting_updated")
               ))
      end

      def danger
        render(Meetings::UpdateFlashComponent.new(
                 button_path_object: @meeting,
                 message: I18n.t("notice_meeting_updated"),
                 scheme: :danger,
                 icon: :stop
               ))
      end

      def button
        render(Meetings::UpdateFlashComponent.new(
                 button_path_object: @meeting,
                 message: I18n.t("notice_meeting_updated"),
                 scheme: :success,
                 icon: :check,
                 button: true,
                 button_message: I18n.t("label_meeting_reload")
                 # button_path_object: # TODO
               ))
      end
    end
  end
end
