# frozen_string_literal: true

module Cde
  # Root module for CDE plugin
  module Engine
    class << self
      def name
        'OpenProject CDE Plugin'
      end

      def version
        '0.1.0'
      end

      def description
        'ISO 19650-compliant Common Data Environment for OpenProject'
      end
    end
  end
end
