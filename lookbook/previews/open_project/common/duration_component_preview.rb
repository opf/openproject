module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class DurationComponentPreview < Lookbook::Preview
      # @param duration number
      # @param type select { choices: [seconds, minutes, hours, days, weeks, months, years] }
      # @param separator text
      # @param abbreviated toggle
      def default(duration: 1234, type: :minutes, separator: ", ", abbreviated: false)
        render OpenProject::Common::DurationComponent.new(duration, type, separator:, abbreviated:)
      end

      def system_arguments
        render OpenProject::Common::DurationComponent.new(3625, :seconds, color: :subtle)
      end

      def iso8601
        render OpenProject::Common::DurationComponent.new("P3DT12H5M", :seconds, color: :subtle)
      end

      def plain_text
        render_with_template
      end
    end
  end
end
