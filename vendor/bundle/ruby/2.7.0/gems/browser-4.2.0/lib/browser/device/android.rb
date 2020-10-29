# frozen_string_literal: true

module Browser
  class Device
    class Android < Base
      def id
        :unknown
      end

      def name
        ua[/\(Linux.*?; Android.*?; ([-_a-z0-9 ]+) Build[^)]+\)/i, 1] ||
          "Unknown"
      end

      def match?
        ua =~ /Android/
      end
    end
  end
end
