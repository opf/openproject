module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class RelativeTimeComponentPreview < Lookbook::Preview
      def default(datetime: (Time.now - 123456.seconds))
        render OpPrimer::RelativeTimeComponent.new(datetime:)
      end

      def german_locale(datetime: Time.parse("2023-10-25T09:06:03Z"))
        I18n.with_locale(:de) do
          render OpPrimer::RelativeTimeComponent.new(datetime:)
        end
      end
    end
  end
end
