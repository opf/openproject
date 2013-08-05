module OpenProject
  module MyProjectPage
    module Version
      def to_s
        [major, minor, patch].join('.')
      end

      def full
        to_s
      end

      def major
        3
      end

      def minor
        0
      end

      def patch
        0
      end

      extend self
    end
  end
end
